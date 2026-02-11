import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final _mobileNumber = TextEditingController();
  final _dateOfBirth = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _signup() async {
    setState(() => _loading = true);
    try {
      // Sign up with Supabase
      final response = await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );

      if (response.user != null) {
        // Create profile in Supabase
        await Supabase.instance.client.from('profiles').upsert({
          'uid': response.user!.id,
          'fullName': _fullName.text.trim(),
          'email': _email.text.trim(),
          'phone': _mobileNumber.text.trim(),
          'favorites': [],
        });
        await UserData.loadFromSupabase();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully!')));
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Signup failed')));
      }
    } catch (e) {
      print('Signup error: $e');
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
              placeholder: 'example@example.com',
            ),
            const SizedBox(height: 20),

            // Mobile Number Field (auto-format)
            _buildInputField(
              label: 'Mobile Number',
              controller: _mobileNumber,
              placeholder: 'XXX-XXX-XXXX',
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _PhoneNumberFormatter(),
              ],
            ),
            const SizedBox(height: 20),

            // Date of Birth Field (auto-format)
            _buildInputField(
              label: 'Date Of Birth',
              controller: _dateOfBirth,
              placeholder: 'DD / MM / YYYY',
              keyboardType: TextInputType.datetime,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _DateOfBirthFormatter(),
              ],
            ),
            const SizedBox(height: 24),

            // Legal Text
            Wrap(
              children: [
                const Text(
                  'By continuing, you agree to ',
                  style: TextStyle(color: Color(0xFF718096), fontSize: 14),
                ),
                GestureDetector(
                  onTap: () => _showTermsDialog(context),
                  child: const Text(
                    'Terms of Use',
                    style: TextStyle(
                      color: primary,
                      decoration: TextDecoration.underline,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Text(
                  ' and ',
                  style: TextStyle(color: Color(0xFF718096), fontSize: 14),
                ),
                GestureDetector(
                  onTap: () => _showPrivacyDialog(context),
                  child: const Text(
                    'Privacy Policy.',
                    style: TextStyle(
                      color: primary,
                      decoration: TextDecoration.underline,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

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

// Phone number formatter
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    String formatted = '';
    if (digits.length >= 3) {
      formatted += digits.substring(0, 3);
      if (digits.length >= 6) {
        formatted += '-' + digits.substring(3, 6);
        if (digits.length > 6) {
          formatted += '-' +
              digits.substring(6, digits.length > 10 ? 10 : digits.length);
        }
      } else {
        formatted += '-' + digits.substring(3);
      }
    } else {
      formatted = digits;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Date of birth formatter
class _DateOfBirthFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    String formatted = '';
    if (digits.length >= 2) {
      formatted += digits.substring(0, 2);
      if (digits.length >= 4) {
        formatted += ' / ' + digits.substring(2, 4);
        if (digits.length > 4) {
          formatted += ' / ' +
              digits.substring(4, digits.length > 8 ? 8 : digits.length);
        }
      } else {
        formatted += ' / ' + digits.substring(2);
      }
    } else {
      formatted = digits;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
