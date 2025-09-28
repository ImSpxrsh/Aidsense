import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
                  Icon(Icons.security, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Your privacy is our priority. Last updated: September 2025',
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
              '1. INFORMATION WE COLLECT',
              'We collect information you provide directly to us:\n\n• Account Information: Name, email address, password\n• Profile Data: Zip code, phone number, profile photo\n• Usage Data: Resources viewed, searches performed, chat interactions\n• Device Information: Device type, operating system, app version\n• Location Data: Approximate location (with your permission) to show nearby resources\n\nWe do NOT collect:\n• Social security numbers or government IDs\n• Financial information or payment details\n• Sensitive health information\n• Information about your use of specific social services',
            ),
            
            _buildSection(
              '2. HOW WE USE YOUR INFORMATION',
              'We use your information to:\n\n• Provide personalized resource recommendations\n• Show resources near your location\n• Improve our AI chat assistant responses\n• Send important app updates and notifications\n• Analyze usage patterns to improve our service\n• Ensure app security and prevent fraud\n• Comply with legal obligations\n\nWe will NEVER:\n• Sell your personal information to third parties\n• Share your data with resource providers without consent\n• Use your information for advertising purposes\n• Contact you for marketing without permission',
            ),
            
            _buildSection(
              '3. INFORMATION SHARING AND DISCLOSURE',
              'We may share your information only in these limited circumstances:\n\n• Service Providers: Third-party companies that help us operate the app (hosting, analytics, customer support) under strict confidentiality agreements\n• Legal Requirements: When required by law, court order, or government investigation\n• Safety Protection: To protect the rights, property, or safety of AidSense, our users, or the public\n• Business Transfers: If we sell or transfer our business, user information may be part of that transaction\n\nWe require all third parties to maintain the same level of data protection as we do.',
            ),
            
            _buildSection(
              '4. DATA SECURITY',
              'We implement comprehensive security measures:\n\n• Encryption: All data is encrypted in transit and at rest\n• Access Controls: Limited employee access on a need-to-know basis\n• Regular Audits: Quarterly security assessments and penetration testing\n• Secure Infrastructure: Cloud hosting with enterprise-grade security\n• Incident Response: Rapid response plan for any security events\n\nWhile we strive to protect your information, no method of transmission over the internet is 100% secure. We encourage you to use strong passwords and keep your login credentials confidential.',
            ),
            
            _buildSection(
              '5. YOUR PRIVACY RIGHTS',
              'You have the following rights regarding your personal information:\n\n• Access: Request a copy of the personal information we have about you\n• Correction: Update or correct inaccurate information\n• Deletion: Request deletion of your personal information\n• Portability: Receive your data in a portable format\n• Opt-out: Unsubscribe from non-essential communications\n• Location Control: Turn off location sharing at any time\n\nTo exercise these rights, contact us at privacy@aidsense.com. We will respond within 30 days.',
            ),
            
            _buildSection(
              '6. CHILDREN\'S PRIVACY',
              'AidSense is not intended for children under 13. We do not knowingly collect personal information from children under 13. If we discover we have collected information from a child under 13, we will delete it immediately.\n\nIf you believe we have collected information from a child under 13, please contact us at privacy@aidsense.com.',
            ),
            
            _buildSection(
              '7. LOCATION DATA',
              'We use location data to:\n• Show resources near you\n• Provide accurate directions\n• Improve local resource recommendations\n\nYou can:\n• Enable/disable location sharing in app settings\n• Use the app without location services (with limited functionality)\n• Delete location history at any time\n\nWe store location data for up to 90 days to improve our service, then automatically delete it.',
            ),
            
            _buildSection(
              '8. COOKIES AND TRACKING',
              'We use minimal tracking technologies:\n\n• Essential Cookies: Required for app functionality\n• Analytics: Anonymous usage statistics to improve the app\n• Preferences: Remember your settings and preferences\n\nWe do NOT use:\n• Advertising cookies or trackers\n• Social media tracking pixels\n• Cross-site tracking technologies\n\nYou can manage cookie preferences in your device settings.',
            ),
            
            _buildSection(
              '9. DATA RETENTION',
              'We keep your information only as long as necessary:\n\n• Account Data: Until you delete your account\n• Usage Data: 2 years for service improvement\n• Chat History: 1 year or until you delete it\n• Location Data: 90 days maximum\n• Support Communications: 3 years for quality assurance\n\nWhen you delete your account, we permanently delete your personal information within 30 days.',
            ),
            
            _buildSection(
              '10. INTERNATIONAL USERS',
              'AidSense is based in the United States. If you use our app from outside the US, your information will be transferred to and processed in the United States.\n\nWe provide appropriate safeguards for international data transfers and comply with applicable data protection laws.',
            ),
            
            _buildSection(
              '11. CHANGES TO THIS PRIVACY POLICY',
              'We may update this Privacy Policy to reflect changes in our practices or applicable laws. We will:\n\n• Notify you via email for significant changes\n• Update the "Last Updated" date\n• Provide 30 days notice before changes take effect\n• Never reduce your privacy rights without explicit consent\n\nContinued use after changes constitutes acceptance of the updated policy.',
            ),
            
            _buildSection(
              '12. CONTACT US',
              'For privacy-related questions or requests:\n\nPrivacy Officer\nAidSense Inc.\nEmail: privacy@aidsense.com\nPhone: (201) 555-0123\nAddress: 123 Community Way, Jersey City, NJ 07302\n\nFor general support: support@aidsense.com\nFor security issues: security@aidsense.com',
            ),
            
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.favorite, color: Colors.purple[700], size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'We respect your privacy and are committed to protecting your personal information.',
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