import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_data.dart';
import 'app_events.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/login_callback_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/resource_detail_screen.dart';
import 'screens/profile_screens.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/about_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

String? _safeDotenvValue(String key) {
  try {
    return dotenv.env[key];
  } catch (_) {
    return null;
  }
}

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    const supabaseUrlFromDefine = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKeyFromDefine =
        String.fromEnvironment('SUPABASE_ANON_KEY');
    var dotenvLoaded = false;

    // Load .env when available (optional in release where secrets come from dart-define).
    try {
      await dotenv.load(fileName: ".env");
      dotenvLoaded = true;
    } catch (e) {
      final message = e.toString();
      final missingFile = message.contains('FileNotFoundError') ||
          message.contains('file not found') ||
          message.contains('Unable to load asset');
      if (!missingFile) {
        debugPrint('Optional .env load failed: $e');
      }
    }

    // Keep startup resilient on iOS: don't block launch indefinitely.
    var supabaseInitialized = false;

    // Always initialize Supabase before runApp when config is available.
    final supabaseUrl = supabaseUrlFromDefine.isNotEmpty
        ? supabaseUrlFromDefine
        : (dotenvLoaded ? _safeDotenvValue('SUPABASE_URL') : null);
    final supabaseAnonKey = supabaseAnonKeyFromDefine.isNotEmpty
        ? supabaseAnonKeyFromDefine
        : (dotenvLoaded ? _safeDotenvValue('SUPABASE_ANON_KEY') : null);
    if (supabaseUrl == null || supabaseAnonKey == null) {
      debugPrint('SUPABASE_URL or SUPABASE_ANON_KEY is not set in .env');
    } else {
      try {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
        ).timeout(const Duration(seconds: 10));
        supabaseInitialized = true;
        debugPrint('Supabase initialized successfully');
      } catch (e) {
        debugPrint('Supabase initialize failed or timed out: $e');
      }
    }

    if (supabaseInitialized) {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        if (data.event == AuthChangeEvent.signedIn && data.session != null) {
          try {
            final client = Supabase.instance.client;
            final uid = client.auth.currentUser?.id;

            if (uid != null && uid.isNotEmpty) {
              try {
                await UserData.ensureProfileRow();
              } catch (e) {
                debugPrint('Profile ensure failed: $e');
              }
            }

            await UserData.loadFromSupabase();
            // Signal app to refresh resources/location now that a user signed in.
            try {
              AppEvents.refreshResources();
            } catch (_) {}
          } catch (e) {
            debugPrint('Auth signedIn profile sync: $e');
          }
        }
        if (data.event == AuthChangeEvent.signedOut) {
          UserData.clearUser();
        }
      });
    }

    FlutterError.onError = (details) {
      final err = details.exception;
      final msg = err.toString();
      if (msg.contains('Code verifier could not be found')) {
        // Ignore duplicate PKCE/deeplink race errors triggered by rapid or
        // fallback OAuth flows (first attempt may leave no verifier).
        if (kDebugMode) debugPrint('Ignored PKCE race error: $msg');
        return;
      }
      FlutterError.dumpErrorToConsole(details);
    };

    runApp(const ProviderScope(child: AidSenseApp()));
  }, (error, stack) {
    final msg = error.toString();
    if (msg.contains('Code verifier could not be found')) {
      if (kDebugMode) debugPrint('Ignored PKCE race error (zone): $msg');
      return;
    }
    FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack));
  });
}

bool _isLoginCallbackUri(Uri uri) {
  return uri.host == 'login-callback' ||
      uri.path.contains('login-callback') ||
      uri.toString().startsWith('com.aidsense.app://login-callback');
}

class AidSenseApp extends StatelessWidget {
  const AidSenseApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF48A8A);
    return MaterialApp(
      title: 'AidSense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary),
        useMaterial3: true,
        fontFamily: 'SF Pro',
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      initialRoute: '/splash',
      navigatorKey: navigatorKey,
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        if (kDebugMode) debugPrint('onGenerateRoute: $name');
        try {
          final uri = Uri.parse(name);
          final hasCode = uri.queryParameters.containsKey('code');
          final hasError = uri.queryParameters.containsKey('error');
          if (hasCode || hasError || _isLoginCallbackUri(uri)) {
            return MaterialPageRoute(
              builder: (_) => const LoginCallbackScreen(),
              settings: settings,
            );
          }
        } catch (_) {}
        return null; // fall back to routes map
      },
      onUnknownRoute: (settings) {
        final name = settings.name ?? '';
        if (kDebugMode) debugPrint('onUnknownRoute: $name');
        try {
          final uri = Uri.parse(name);
          final hasCode = uri.queryParameters.containsKey('code');
          final hasError = uri.queryParameters.containsKey('error');
          if (hasCode || hasError || _isLoginCallbackUri(uri)) {
            return MaterialPageRoute(
              builder: (_) => const LoginCallbackScreen(),
              settings: settings,
            );
          }
        } catch (_) {}
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      },
      routes: {
        '/login-callback': (_) => const LoginCallbackScreen(),
        '/login-callback/': (_) => const LoginCallbackScreen(),
        '/splash': (_) => const SplashScreen(),
        '/': (_) => const WelcomeScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/reset': (_) => const ResetPasswordScreen(),
        '/home': (_) => const HomeScreen(),
        '/resource': (_) => const ResourceDetailScreen(),
        '/favorites': (_) => const FavoritesScreen(),
        '/offline-saved': (_) => const OfflineSavedResourcesScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/password': (_) => const PasswordManagerScreen(),
        '/help': (_) => const HelpCenterScreen(),
        '/notifications': (_) => const NotificationsScreen(),
        '/privacy': (_) => const PrivacyPolicyScreen(),
        '/about': (_) => const AboutScreen(),
      },
    );
  }
}
