import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_data.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/resource_detail_screen.dart';
import 'screens/profile_screens.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/about_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Always load .env before anything else
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Error loading .env: $e');
  }

  // Always initialize Supabase before runApp
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('SUPABASE_URL or SUPABASE_ANON_KEY is not set in .env');
  }
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  debugPrint('Supabase initialized successfully');

  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    if (data.event == AuthChangeEvent.signedIn && data.session != null) {
      try {
        await UserData.ensureProfileRow();
        await UserData.loadFromSupabase();
      } catch (e) {
        debugPrint('Auth signedIn profile sync: $e');
      }
    }
    if (data.event == AuthChangeEvent.signedOut) {
      UserData.clearUser();
    }
  });

  runApp(const ProviderScope(child: AidSenseApp()));
}

class AidSenseApp extends StatelessWidget {
  const AidSenseApp({super.key});

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
      routes: {
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
