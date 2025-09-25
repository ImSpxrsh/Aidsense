import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/resource_detail_screen.dart';
import 'screens/profile_screens.dart';
import 'screens/admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AidSenseApp());
}

class AidSenseApp extends StatelessWidget {
  const AidSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFFF48A8A);
    return MaterialApp(
      title: 'AidSense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary),
        useMaterial3: true,
        fontFamily: 'SF Pro',
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
        '/settings': (_) => const SettingsScreen(),
        '/password': (_) => const PasswordManagerScreen(),
        '/help': (_) => const HelpCenterScreen(),
        '/notifications': (_) => const NotificationsScreen(),
        '/admin': (_) => const AdminScreen(),
      },
    );
  }
}
