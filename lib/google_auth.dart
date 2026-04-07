import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_redirect.dart';

const _webClientSuffix = '.apps.googleusercontent.com';

/// Redirect URI Google may use during **native** Android/iOS sign-in for your **Web** OAuth client.
/// Add this exact string in Google Cloud → Credentials → your **Web** client → Authorized redirect URIs.
String googleNativeRedirectUriForWebClientId(String webClientId) {
  final id = webClientId.trim();
  if (!id.endsWith(_webClientSuffix)) return '';
  final prefix = id.substring(0, id.length - _webClientSuffix.length);
  return 'com.googleusercontent.apps.$prefix:/oauth2redirect';
}

String? _webClientIdFromEnv() {
  var v = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim();
  if (v == null || v.isEmpty) return null;
  if ((v.startsWith('"') && v.endsWith('"')) ||
      (v.startsWith("'") && v.endsWith("'"))) {
    v = v.substring(1, v.length - 1).trim();
  }
  return v.isEmpty ? null : v;
}

/// Google sign-in for Supabase.
///
/// **Android / iOS:** Uses the native Google Sign-In SDK + [signInWithIdToken], so Google’s
/// browser `redirect_uri` is **not** used — this avoids `redirect_uri_mismatch` when the Web
/// OAuth client in Google Cloud is misconfigured.
///
/// Add to `.env` (same **Web** client ID string you use in Supabase → Google → Client ID):
/// `GOOGLE_WEB_CLIENT_ID=123456789-xxxx.apps.googleusercontent.com`
///
/// **iOS only (if sign-in fails):** add `GOOGLE_IOS_CLIENT_ID` = your **iOS** OAuth client ID
/// from Google Cloud, and ensure the reversed client ID URL scheme is in `Info.plist` per
/// [google_sign_in](https://pub.dev/packages/google_sign_in) iOS setup.
///
/// **Web / desktop:** Falls back to [signInWithOAuth] (needs redirect URLs + Google Web client).
Future<void> signInWithGoogleForSupabase() async {
  final supabase = Supabase.instance.client;

  final useNativeSdk = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  if (!useNativeSdk) {
    if (kDebugMode) {
      debugPrint(
        'Google sign-in: using browser OAuth ($defaultTargetPlatform). '
        'For redirect_uri_mismatch, fix Web client URIs or run on Android/iOS.',
      );
    }
    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: supabaseOAuthRedirectUrl(),
    );
    return;
  }

  final webClientId = _webClientIdFromEnv();
  if (webClientId == null) {
    throw StateError(
      'Add GOOGLE_WEB_CLIENT_ID to your .env file. '
      'Use the Google Cloud **Web application** OAuth client ID (same as in Supabase). '
      'Stop the app fully and run again after editing .env (hot reload does not reload .env).',
    );
  }
  if (!webClientId.endsWith(_webClientSuffix)) {
    throw StateError(
      'GOOGLE_WEB_CLIENT_ID should end with $_webClientSuffix (Web OAuth client ID).',
    );
  }

  if (kDebugMode) {
    final nativeRedirect = googleNativeRedirectUriForWebClientId(webClientId);
    debugPrint(
      'Google native sign-in. If you see redirect_uri_mismatch in a browser/WebView, '
      'add this to the **same Web OAuth client** in Google Cloud → Authorized redirect URIs: '
      '$nativeRedirect',
    );
  }

  final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID']?.trim();

  final googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile', 'openid'],
    serverClientId: webClientId,
    clientId: defaultTargetPlatform == TargetPlatform.iOS &&
            iosClientId != null &&
            iosClientId.isNotEmpty
        ? iosClientId
        : null,
  );

  final account = await googleSignIn.signIn();
  if (account == null) {
    return;
  }

  final googleAuth = await account.authentication;
  final idToken = googleAuth.idToken;
  if (idToken == null || idToken.isEmpty) {
    throw StateError(
      'No Google ID token. On Android, check SHA-1 in Google Cloud for your app. '
      'On iOS, set GOOGLE_IOS_CLIENT_ID and Info.plist URL scheme per google_sign_in docs.',
    );
  }

  await supabase.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: idToken,
    accessToken: googleAuth.accessToken,
  );
}
