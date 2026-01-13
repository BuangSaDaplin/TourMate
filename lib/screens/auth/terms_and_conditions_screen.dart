import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TOURIST BOOKING, CANCELLATION & EMERGENCY WAIVER',
              style: AppTheme.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildSection('1. Booking Agreement', [
              'By submitting a booking request through the platform, I confirm that:',
              '• All information I provide is accurate and complete.',
              '• My booking request is subject to approval by the assigned tour guide.',
              '• A booking is considered confirmed only after guide approval.',
            ]),
            _buildSection('2. Package Tour Acknowledgment', [
              'I understand that:',
              '• All tours offered on the platform are package-based tours.',
              '• Each tour package is provided as a single, complete service.',
              '• Partial participation, partial cancellations, or partial refunds are not permitted.',
            ]),
            _buildSection('3. Payment & Fees', [
              '• Payment will be collected only after the tour guide approves the booking.',
              '• Platform service fees are processed internally and may not be itemized in the booking summary.',
              '• The amount shown represents the final total payable.',
            ]),
            _buildSection('4. Cancellation Policy', [
              'I agree and acknowledge that:',
              '• Once the tour has started, cancellations, refunds, or changes are not allowed, regardless of reason.',
              '• Failure to show up before the tour starts ("no-show") may result in full forfeiture of the tour package amount.',
            ]),
            _buildSection('5. Emergency Cancellations', [
              'In the event of an emergency (including medical emergencies, natural disasters, or government-imposed restrictions):',
              '• Emergency cancellations are only considered if the tour has NOT yet started.',
              '• I agree to notify the tour guide or platform as soon as reasonably possible.',
              '• Emergency cases are reviewed on a case-by-case basis.',
              '• Any approved refund or reschedule applies to the entire tour package.',
            ]),
            _buildSection('6. Assumption of Risk', [
              '• I acknowledge that tours may involve physical activities and environmental risks.',
              '• I voluntarily assume all risks associated with participation.',
              '• I confirm that I am physically and mentally capable of participating in the tour.',
            ]),
            _buildSection('7. Limitation of Liability', [
              '• The platform acts solely as a booking intermediary.',
              '• The tour guide is an independent service provider responsible for tour execution and safety.',
              '• The platform is not liable for injuries, losses, or damages incurred during the tour.',
            ]),
            const SizedBox(height: 24),
            Text(
              'TOUR GUIDE BOOKING, CANCELLATION & EMERGENCY WAIVER',
              style: AppTheme.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildSection('1. Guide Responsibilities', [
              'By offering tours through the platform, I confirm that:',
              '• All tour information provided is accurate, complete, and up to date.',
              '• I will conduct tours professionally and prioritize participant safety.',
              '• I comply with all applicable laws, permits, and safety regulations.',
            ]),
            _buildSection('2. Independent Contractor Acknowledgment', [
              'I understand that:',
              '• I operate as an independent service provider, not an employee of the platform.',
              '• The platform acts only as a booking and communication intermediary.',
            ]),
            _buildSection('3. Booking Acceptance', [
              '• I reserve the right to accept or decline booking requests before approval.',
              '• Once a booking is approved, I commit to delivering the entire tour package as advertised.',
            ]),
            _buildSection('4. Package Tour Cancellation Policy', [
              'I acknowledge and agree that:',
              '• Tours offered are package-based and must be delivered as a complete service.',
              '• Once the tour has started, I may not cancel, abandon, partially deliver service, or accept another tour.',
            ]),
            _buildSection('5. Emergency Cancellations', [
              'In case of emergencies (including illness, accidents, extreme weather, or force majeure events):',
              '• I must notify tourists and the platform immediately.',
              '• Emergency cases are reviewed on a case-by-case basis.',
              '• Any approved refund or reschedule applies to the entire tour package.',
            ]),
            _buildSection('6. Safety & Liability', [
              '• I am responsible for implementing reasonable safety measures during the tour.',
              '• I accept liability for negligence or failure to comply with safety standards.',
              '• I must act in good faith to protect participants at all times.',
            ]),
            _buildSection('7. Account Standing', [
              'Repeated cancellations or violations of platform policies may result in:',
              '• Reduced visibility',
              '• Temporary suspension',
              '• Permanent removal from the platform',
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
