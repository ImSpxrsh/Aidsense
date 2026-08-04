import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth_redirect.dart';
import 'user_data.dart';

const _lastKnownPositionCacheKey = 'last_known_user_position_v1';
const _resourceCacheKey = 'nearby_resources_cache_v2';

class AccountNotFoundForGoogleSignIn implements Exception {
  final String message;
  const AccountNotFoundForGoogleSignIn([
    this.message = 'No account found. Please sign up first.',
  ]);

  @override
  String toString() => message;
}

bool _oauthInProgress = false;

String _generateRawNonce([int length = 32]) {
  final random = Random.secure();
  final bytes = List<int>.generate(length, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

class SocialSignInCancelledException implements Exception {
  final String message;
  const SocialSignInCancelledException(this.message);

  @override
  String toString() => message;
}

Future<bool> _waitForSupabaseSession(
    {Duration timeout = const Duration(seconds: 8)}) async {
  final client = Supabase.instance.client;
  if (client.auth.currentSession != null) return true;

  final completer = Completer<void>();
  final subscription = client.auth.onAuthStateChange.listen((data) {
    if (data.session != null && !completer.isCompleted) {
      completer.complete();
    }
  });

  try {
    await completer.future.timeout(timeout, onTimeout: () {});
  } finally {
    await subscription.cancel();
  }

  final hasSession = client.auth.currentSession != null;
  if (hasSession) {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
  return hasSession;
}

Future<void> signOutAll() async {
  try {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}

    try {
      UserData.clearUser();
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastKnownPositionCacheKey);
      await prefs.remove(_resourceCacheKey);
    } catch (_) {}
  } catch (_) {}
}

String? _trimmedEnv(String key) {
  var value = dotenv.env[key]?.trim();
  if (value == null || value.isEmpty) return null;
  if ((value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))) {
    value = value.substring(1, value.length - 1).trim();
  }
  return value.isEmpty ? null : value;
}

Future<void> signInWithGoogleForSupabase({
  bool requireExistingProfile = false,
}) async {
  final supabase = Supabase.instance.client;

  if (_oauthInProgress) return;
  _oauthInProgress = true;
  try {
    final useNative = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    if (!useNative) {
      if (kDebugMode) {
        debugPrint(
            'Google sign-in: using browser OAuth on $defaultTargetPlatform.');
      }
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: supabaseOAuthRedirectUrl(),
        authScreenLaunchMode: LaunchMode.inAppBrowserView,
      );
      return;
    }

    final webClientId = _trimmedEnv('GOOGLE_WEB_CLIENT_ID');
    if (webClientId == null) {
      throw StateError(
        'Set GOOGLE_WEB_CLIENT_ID in .env using the Google Cloud Web OAuth client ID.',
      );
    }

    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile', 'openid'],
      serverClientId: webClientId,
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? _trimmedEnv('GOOGLE_IOS_CLIENT_ID')
          : null,
    );

    final account = await googleSignIn.signIn();
    if (account == null) {
      // User cancelled the sign-in dialog
      return;
    }

    late String idToken;
    late String? accessToken;
    try {
      final googleAuth = await account.authentication;
      idToken = googleAuth.idToken ?? '';
      accessToken = googleAuth.accessToken;
      if (idToken.isEmpty) {
        throw StateError(
          'No Google ID token. Check Google OAuth client IDs and the iOS URL scheme in Info.plist.',
        );
      }
    } catch (e) {
      try {
        await googleSignIn.signOut();
      } catch (_) {}
      rethrow;
    }

    try {
      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      final hasSession = await _waitForSupabaseSession();
      if (!hasSession) {
        throw StateError(
          'Google sign-in succeeded but the app session was not established. Please try again.',
        );
      }
    } catch (e) {
      try {
        await googleSignIn.signOut();
      } catch (_) {}
      rethrow;
    }

    // Ensure profile row exists after successful sign-in
    try {
      await UserData.ensureProfileRow();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Warning: Could not create profile row: $e');
      }
      // Don't fail the sign-in if profile row creation fails (RLS, etc.)
    }

    if (requireExistingProfile) {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null || uid.isEmpty) {
        await supabase.auth.signOut();
        throw const AccountNotFoundForGoogleSignIn();
      }

      final exists = await _hasExistingProfileRow(supabase, uid);
      if (!exists) {
        try {
          await googleSignIn.signOut();
        } catch (_) {}
        await supabase.auth.signOut();
        throw const AccountNotFoundForGoogleSignIn();
      }
    }
  } finally {
    _oauthInProgress = false;
  }
}

Future<void> signInWithAppleForSupabase() async {
  final supabase = Supabase.instance.client;

  if (_oauthInProgress) return;
  _oauthInProgress = true;
  try {
    if (kIsWeb) {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: supabaseOAuthRedirectUrl(),
        authScreenLaunchMode: LaunchMode.inAppBrowserView,
      );
      return;
    }

    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: supabaseOAuthRedirectUrl(),
        authScreenLaunchMode: LaunchMode.inAppBrowserView,
      );
      return;
    }

    final rawNonce = _generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    late AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
    } catch (e) {
      if (e is SignInWithAppleAuthorizationException &&
          e.code == AuthorizationErrorCode.canceled) {
        throw const SocialSignInCancelledException('Apple sign-in cancelled.');
      }
      if (kDebugMode) {
        debugPrint('Apple sign-in credential error: $e');
      }
      throw StateError('Apple sign-in failed. Please try again.');
    }

    final idToken = credential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('No identity token returned from Apple sign-in');
    }

    try {
      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      final hasSession = await _waitForSupabaseSession();
      if (!hasSession) {
        throw StateError(
          'Apple sign-in succeeded but the app session was not established. Please try again.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Apple Supabase sign-in error: $e');
      }
      rethrow;
    }

    try {
      await UserData.ensureProfileRow();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Warning: Could not create profile row: $e');
      }
    }

    if (credential.givenName != null || credential.familyName != null) {
      final nameParts = <String>[];
      if (credential.givenName != null) nameParts.add(credential.givenName!);
      if (credential.familyName != null) nameParts.add(credential.familyName!);
      final fullName = nameParts.join(' ');
      try {
        await supabase.auth.updateUser(
          UserAttributes(data: {
            'full_name': fullName,
            'given_name': credential.givenName,
            'family_name': credential.familyName,
          }),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Warning: Could not update user metadata: $e');
        }
      }
    }
  } finally {
    _oauthInProgress = false;
  }
}

Future<bool> _hasExistingProfileRow(SupabaseClient client, String uid) async {
  try {
    final byUid = await client
        .from('profiles')
        .select('uid')
        .eq('uid', uid)
        .maybeSingle();
    if (byUid != null) return true;

    final byId =
        await client.from('profiles').select('id').eq('id', uid).maybeSingle();
    return byId != null;
  } catch (_) {
    return false;
  }
}
