import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Create scale animation for logo pop-out effect
    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    // Start animation
    _animationController.forward();

    // Initialize app
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    bool onboardingComplete = false;
    bool hasSession = false;
    try {
      onboardingComplete = await ref.read(onboardingCompleteProvider.future);
    } catch (_) {
      onboardingComplete = false;
    }

    try {
      await Future.delayed(const Duration(seconds: 2));

      // Read session as late as possible to avoid racing with auth state restore.
      hasSession = Supabase.instance.client.auth.currentSession != null;
      if (!hasSession) {
        try {
          await Supabase.instance.client.auth.onAuthStateChange.first
              .timeout(const Duration(milliseconds: 1200));
        } catch (_) {
          // Ignore timeout/errors and use current known session state.
        }
        hasSession = Supabase.instance.client.auth.currentSession != null;
      }
    } catch (e) {
      debugPrint('Splash init fallback due to startup error: $e');
      hasSession = false;
    }

    if (mounted) {
      final nextRoute =
          hasSession ? '/home' : (onboardingComplete ? '/' : '/onboarding');
      Navigator.pushReplacementNamed(context, nextRoute);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Image.asset(
                'assets/images/Logo.png',
                width: 200,
                height: 200,
              ),
            );
          },
        ),
      ),
    );
  }
}
