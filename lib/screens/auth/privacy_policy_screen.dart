import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: AppTheme.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildSection('1. Information We Collect', [
              'We collect only the information necessary to operate the Platform effectively.',
              '',
              'a. Information You Provide',
              'When you register or use the Platform, we may collect:',
              '• Full name',
              '• Email address',
              '• Contact number',
              '• Account role (Tourist or Tour Guide)',
              '• Booking details (selected tour, date, time, number of participants)',
              '• Tour information provided by guides (tour details, pricing, schedules)',
              '',
              'b. Automatically Collected Information',
              'We may collect limited technical information such as:',
              '• Device type',
              '• App usage data (for improving features and performance)',
            ]),
            _buildSection('2. How We Use Your Information', [
              'Your information is used to:',
              '• Create and manage user accounts',
              '• Process tour bookings and approvals',
              '• Enable communication between tourists and tour guides',
              '• Display booking summaries and tour details',
              '• Improve system performance and user experience',
              '• Ensure compliance with platform policies and waivers',
              '',
              'We do not sell or rent your personal data to third parties.',
            ]),
            _buildSection('3. Booking & Transaction Data', [
              'Booking information is shared only between the tourist, the assigned tour guide, and the platform.',
              '',
              'Payment-related details are used solely for booking confirmation and record-keeping.',
              '',
              'Platform service fees are processed internally and are not publicly disclosed.',
            ]),
            _buildSection('4. Data Sharing & Disclosure', [
              'We only share data when necessary:',
              '• Between tourists and tour guides for confirmed bookings',
              '• When required by law or legal process',
              '• To protect the safety, rights, or integrity of users and the platform',
              '',
              'No unnecessary personal data is disclosed to unauthorized parties.',
            ]),
            _buildSection('5. Data Storage & Security', [
              'User data is stored securely using cloud-based services (such as Firebase).',
              '',
              'Reasonable technical and administrative safeguards are applied to protect data from unauthorized access, loss, or misuse.',
              '',
              'Access to sensitive data is limited to authorized system components only.',
            ]),
            _buildSection('6. User Responsibilities', [
              'Users are responsible for:',
              '• Keeping their login credentials confidential',
              '• Providing accurate and truthful information',
              '• Updating account details when necessary',
              '',
              'The platform is not responsible for issues caused by false or outdated user information.',
            ]),
            _buildSection('7. Data Retention', [
              'We retain user and booking data only as long as necessary for platform operations and record purposes.',
              '',
              'Inactive or deleted accounts may have their data removed in accordance with system policies.',
            ]),
            _buildSection('8. Children\'s Privacy', [
              'The Platform is not intended for use by individuals under 18 years old. We do not knowingly collect personal information from minors.',
            ]),
            _buildSection('9. Changes to This Privacy Policy', [
              'We may update this Privacy Policy from time to time.',
              '',
              'Any changes will be posted within the Platform.',
              '',
              'Continued use of the Platform indicates acceptance of the updated policy.',
            ]),
            _buildSection('10. Contact & Support', [
              'If you have questions or concerns about this Privacy Policy or how your data is handled, you may contact the platform support through the app.',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        ...points.map((point) => Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
              child: Text(
                point,
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.justify,
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}
