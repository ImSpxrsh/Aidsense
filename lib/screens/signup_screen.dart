import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../google_auth.dart';
import '../user_data.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _fullName = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted || data.session == null) return;
      if (data.event != AuthChangeEvent.signedIn) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final route = ModalRoute.of(context);
        if (route == null || !route.isCurrent) return;
        Navigator.pushReplacementNamed(context, '/home');
      });
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<bool> _waitForSession() async {
    const attempts = 10;
    const delay = Duration(milliseconds: 200);
    for (var i = 0; i < attempts; i++) {
      if (Supabase.instance.client.auth.currentSession != null) return true;
      await Future.delayed(delay);
    }
    return Supabase.instance.client.auth.currentSession != null;
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await signInWithGoogleForSupabase();
      if (!mounted) return;
      if (await _waitForSession()) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Google sign-in: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _loading = true);
    try {
      await signInWithAppleForSupabase();
      await UserData.ensureProfileRow();
      if (!mounted) return;
      if (await _waitForSession()) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (kDebugMode) {
        debugPrint('Apple sign-in: awaiting callback/session establishment...');
      }
    } on SocialSignInCancelledException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apple sign-in cancelled.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Apple sign-in: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signup() async {
    final email = _email.text.trim();
    final password = _pass.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final fullName = _fullName.text.trim();

      final metadata = <String, dynamic>{
        if (fullName.isNotEmpty) 'full_name': fullName,
      };

      // Sign up with Supabase (metadata is available to triggers / load fallbacks)
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: metadata.isEmpty ? null : metadata,
      );

      if (response.user != null) {
        UserData.saveUser(
          fullName: fullName,
          email: email,
        );

        // Without a session (e.g. "confirm email" enabled), RLS usually blocks writes — keep local data above.
        if (response.session != null) {
          try {
            await Supabase.instance.client.from('profiles').upsert({
              'uid': response.user!.id,
              if (fullName.isNotEmpty) 'fullName': fullName,
              'email': email,
              'favorites': [],
            });
          } catch (e) {
            debugPrint('Profile upsert after signup: $e');
          }
          await UserData.loadFromSupabase();
        }

        final needsConfirm = response.session == null;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              needsConfirm
                  ? 'Check your email to confirm your account, then sign in.'
                  : 'Account created successfully!',
            ),
          ),
        );
        Navigator.pushReplacementNamed(
            context, needsConfirm ? '/login' : '/home');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Signup failed')));
      }
    } catch (e) {
      debugPrint('Signup error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF56565);
    final showAppleSignIn =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            }
          },
        ),
        title: const Text(
          'New Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full Name Field
            _buildInputField(
              label: 'Full name',
              controller: _fullName,
              placeholder: 'Enter your full name',
            ),
            const SizedBox(height: 20),

            // Password Field
            _buildPasswordField(),
            const SizedBox(height: 20),

            // Email Field
            _buildInputField(
              label: 'Email',
              controller: _email,
              placeholder: 'support@aidsense.app',
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'We only ask for the details needed to create and sign in to your account.',
                style: TextStyle(color: Color(0xFF718096), fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),

            // Sign Up Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFB6C1), // Light pink
                    Color(0xFFFFA07A), // Salmon pink
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: ElevatedButton(
                onPressed: _loading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: TextStyle(color: const Color(0xFF718096)),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _loading ? null : _signInWithGoogle,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                foregroundColor: const Color(0xFF2D3748),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/google_logo.png',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text('Continue with Google'),
                ],
              ),
            ),
            if (showAppleSignIn) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loading ? null : _signInWithApple,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  foregroundColor: const Color(0xFF2D3748),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.apple, size: 22),
                    SizedBox(width: 12),
                    Text('Continue with Apple'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Login Link
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Color(0xFF718096), fontSize: 14),
                    children: [
                      TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Log in',
                        style: TextStyle(color: primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: Color(0xFFE53E3E)),
            filled: true,
            fillColor: const Color(0xFFE2E8F0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _pass,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: '............',
            hintStyle: const TextStyle(color: Color(0xFFE53E3E)),
            filled: true,
            fillColor: const Color(0xFFE2E8F0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFFE53E3E),
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
