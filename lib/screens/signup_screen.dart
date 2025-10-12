import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _fullName = TextEditingController();
  final _mobileNumber = TextEditingController();
  final _dateOfBirth = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _signup() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );
      // After sign up, send email verification optionally
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Account created. Verification email sent.')));
      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'Auth error')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Use'),
        content: const SingleChildScrollView(
          child: Text(
            'Welcome to AidSense!\n\n'
            '1. ACCEPTANCE OF TERMS\n'
            'By using AidSense, you agree to these terms.\n\n'
            '2. USE OF SERVICE\n'
            'AidSense connects users with community resources. Use responsibly.\n\n'
            '3. USER CONDUCT\n'
            'Be respectful and honest when using our platform.\n\n'
            '4. PRIVACY\n'
            'We protect your personal information as outlined in our Privacy Policy.\n\n'
            '5. DISCLAIMER\n'
            'Resource information is provided as-is. Always verify details directly.\n\n'
            'For questions, contact: support@aidsense.com',
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'AidSense Privacy Policy\n\n'
            '1. INFORMATION WE COLLECT\n'
            '• Account information (name, email, zip code)\n'
            '• Usage data and preferences\n'
            '• Location data (with permission)\n\n'
            '2. HOW WE USE INFORMATION\n'
            '• Provide personalized resource recommendations\n'
            '• Improve our services\n'
            '• Send important notifications\n\n'
            '3. INFORMATION SHARING\n'
            'We do not sell personal information. We may share data with:\n'
            '• Service providers (with proper safeguards)\n'
            '• Legal authorities (when required)\n\n'
            '4. DATA SECURITY\n'
            'We use industry-standard security measures.\n\n'
            '5. YOUR RIGHTS\n'
            'You can access, update, or delete your data anytime.\n\n'
            'Contact: privacy@aidsense.com\n'
            'Last updated: September 2025',
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF56565);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            _buildInputField(
              label: 'Full name',
              controller: _fullName,
              placeholder: 'Enter your full name',
            ),
            const SizedBox(height: 20),

            PasswordField(controller: _pass),
            const SizedBox(height: 20),

            _buildInputField(
              label: 'Email',
              controller: _email,
              placeholder: 'example@example.com',
            ),
            const SizedBox(height: 20),

            _buildInputField(
              label: 'Mobile Number',
              controller: _mobileNumber,
              placeholder: 'XXX-XXX-XXXX',
            ),
            const SizedBox(height: 20),

            _buildInputField(
              label: 'Date Of Birth',
              controller: _dateOfBirth,
              placeholder: 'DD / MM / YYYY',
            ),
            const SizedBox(height: 24),
            // Sign Up Button
            StatefulBuilder(
              builder: (context, setLocalState) {
                return Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB6C1), Color(0xFFFFA07A)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () async {
                            setLocalState(() => _loading = true);
                            await _signup();
                            setLocalState(() => _loading = false);
                          },
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
                );
              },
            ),

            const SizedBox(height: 24),

            // Social Sign Up
            const Center(
              child: Text(
                'or sign up with',
                style: TextStyle(color: Color(0xFF718096), fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),

            // Social Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton('G', () {}),
                const SizedBox(width: 16),
                _buildSocialButton('f', () {}),
                const SizedBox(width: 16),
                _buildSocialButton('', () {}, icon: Icons.fingerprint),
              ],
            ),
            const SizedBox(height: 32),

            // Login Link
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                child: RichText(
                  text: TextSpan(
                    style:
                        const TextStyle(color: Color(0xFF718096), fontSize: 14),
                    children: [
                      const TextSpan(text: 'already have on account? '),
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

  Widget _buildSocialButton(String text, VoidCallback onTap, {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: Color(0xFFFFB6C1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 24)
              : Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  const PasswordField({required this.controller, super.key});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
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
          controller: widget.controller,
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
