import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF48A8A);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            color: Color(0xFFB71C1C),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Last updated: September 2025',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              '1. ACCEPTANCE OF TERMS',
              'By downloading, accessing, or using the AidSense mobile application ("App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, please do not use our App.\n\nThese Terms constitute a legally binding agreement between you and AidSense Inc. ("Company," "we," "us," or "our").',
            ),
            
            _buildSection(
              '2. DESCRIPTION OF SERVICE',
              'AidSense is a community resource discovery platform that helps users locate and access local social services, including:\n\n• Food banks and pantries\n• Homeless shelters and housing assistance\n• Medical clinics and healthcare services\n• Emergency services and crisis support\n• Educational and job training programs\n\nOur App includes an AI-powered chat assistant to help users find relevant resources quickly and efficiently.',
            ),
            
            _buildSection(
              '3. USER ACCOUNTS AND REGISTRATION',
              'To access certain features, you must create an account by providing:\n• Valid email address\n• Secure password\n• Basic profile information (name, zip code)\n\nYou are responsible for:\n• Maintaining the confidentiality of your account credentials\n• All activities that occur under your account\n• Notifying us immediately of any unauthorized use',
            ),
            
            _buildSection(
              '4. ACCEPTABLE USE POLICY',
              'You agree to use AidSense only for lawful purposes and in accordance with these Terms. You may NOT:\n\n• Provide false or misleading information\n• Attempt to gain unauthorized access to our systems\n• Use the App for any commercial or business purposes\n• Harass, abuse, or harm other users or service providers\n• Upload malicious code or attempt to disrupt the service\n• Violate any applicable local, state, or federal laws',
            ),
            
            _buildSection(
              '5. RESOURCE INFORMATION DISCLAIMER',
              'AidSense aggregates information about community resources from various sources. We strive for accuracy but cannot guarantee that:\n\n• Resource information is always current or complete\n• Services are available when you visit\n• Eligibility requirements haven\'t changed\n• Contact information is up to date\n\nALWAYS verify information directly with service providers before visiting. We are not responsible for any inconvenience caused by outdated information.',
            ),
            
            _buildSection(
              '6. PRIVACY AND DATA PROTECTION',
              'Your privacy is important to us. Our collection and use of personal information is governed by our Privacy Policy, which is incorporated into these Terms by reference. By using AidSense, you consent to the collection and use of your information as described in our Privacy Policy.',
            ),
            
            _buildSection(
              '7. INTELLECTUAL PROPERTY RIGHTS',
              'The AidSense App, including all content, features, and functionality, is owned by AidSense Inc. and is protected by United States and international copyright, trademark, and other intellectual property laws.\n\nYou are granted a limited, non-exclusive, non-transferable license to use the App for personal, non-commercial purposes.',
            ),
            
            _buildSection(
              '8. LIMITATION OF LIABILITY',
              'TO THE MAXIMUM EXTENT PERMITTED BY LAW, AIDSENSE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO LOSS OF PROFITS, DATA, OR OTHER INTANGIBLE LOSSES.\n\nOur total liability to you for all claims shall not exceed \$100 or the amount you paid to use our service (currently \$0), whichever is greater.',
            ),
            
            _buildSection(
              '9. TERMINATION',
              'We may terminate or suspend your account and access to the App immediately, without prior notice, if you breach these Terms.\n\nYou may terminate your account at any time by contacting us at support@aidsense.com. Upon termination, your right to use the App will cease immediately.',
            ),
            
            _buildSection(
              '10. CHANGES TO TERMS',
              'We reserve the right to modify these Terms at any time. We will notify users of significant changes through the App or via email. Continued use of the App after changes constitutes acceptance of the new Terms.',
            ),
            
            _buildSection(
              '11. GOVERNING LAW',
              'These Terms are governed by and construed in accordance with the laws of the State of New Jersey, United States, without regard to conflict of law principles.\n\nAny legal action must be brought in the state or federal courts located in New Jersey.',
            ),
            
            _buildSection(
              '12. CONTACT INFORMATION',
              'If you have questions about these Terms, please contact us:\n\nAidSense Inc.\nEmail: legal@aidsense.com\nPhone: (201) 555-0123\nAddress: 123 Community Way, Jersey City, NJ 07302\n\nFor technical support: support@aidsense.com',
            ),
            
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green[700], size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Thank you for using AidSense to connect with your community resources!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB71C1C),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}