import 'package:flutter/material.dart';
import 'package:tourmate_app/models/guide_verification_model.dart';
import '../../utils/app_theme.dart';

class GuideVerificationStatusScreen extends StatefulWidget {
  const GuideVerificationStatusScreen({super.key});

  @override
  State<GuideVerificationStatusScreen> createState() =>
      _GuideVerificationStatusScreenState();
}

class _GuideVerificationStatusScreenState
    extends State<GuideVerificationStatusScreen> {
  // Mock verification data - replace with actual data fetching
  final GuideVerification? _verification = GuideVerification(
    id: 'ver_001',
    guideId: 'user_123',
    guideName: 'John Doe',
    guideEmail: 'john@example.com',
    bio: 'Experienced tour guide with 5+ years in Cebu tourism',
    idDocumentUrl: ['https://example.com/id_doc.jpg'],
    lguDocumentUrl: ['https://example.com/lgu_doc.jpg'],
    status: VerificationStatus.pending,
    submittedAt: DateTime.now().subtract(const Duration(days: 2)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Verification Status'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _verification == null
            ? _buildNoSubmissionView()
            : _buildVerificationStatusView(),
      ),
    );
  }

  Widget _buildNoSubmissionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 24),
          Text(
            'No Verification Submitted',
            style: AppTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t submitted your guide verification yet.',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Navigate to submit credentials screen
              Navigator.of(context)
                  .pushReplacementNamed('/guide/submit-credentials');
            },
            child: const Text('Submit Credentials'),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatusView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Header
        Text(
          'Verification Status',
          style: AppTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Track the progress of your guide verification application',
          style: AppTheme.bodyMedium,
        ),
        const SizedBox(height: 32),

        // Status Card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Status Icon and Text
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getStatusColor().withOpacity(0.1),
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    size: 40,
                    color: _getStatusColor(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _getStatusTitle(),
                  style: AppTheme.headlineMedium.copyWith(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getStatusDescription(),
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Timeline
                _buildStatusTimeline(),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Submission Details
        Text(
          'Submission Details',
          style: AppTheme.headlineSmall,
        ),
        const SizedBox(height: 16),

        _buildDetailCard(
          'Submitted On',
          _formatDate(_verification!.submittedAt),
          Icons.calendar_today,
        ),

        _buildDetailCard(
          'Guide Bio',
          _verification!.bio ?? 'No bio provided',
          Icons.person,
        ),

        _buildDetailCard(
          'Documents Submitted',
          'Government ID & LGU Certificate',
          Icons.description,
        ),

        if (_verification!.status == VerificationStatus.rejected) ...[
          const SizedBox(height: 32),
          Card(
            color: AppTheme.errorColor.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.errorColor.withOpacity(0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.errorColor),
                      const SizedBox(width: 8),
                      Text(
                        'Rejection Reason',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _verification!.rejectionReason ??
                        'No specific reason provided.',
                    style: AppTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to resubmit screen
                      Navigator.of(context)
                          .pushNamed('/guide/resubmit-credentials');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Resubmit Credentials'),
                  ),
                ],
              ),
            ),
          ),
        ],

        if (_verification!.status == VerificationStatus.approved) ...[
          const SizedBox(height: 32),
          Card(
            color: AppTheme.successColor.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.successColor.withOpacity(0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified, color: AppTheme.successColor),
                      const SizedBox(width: 8),
                      Text(
                        'Verification Approved!',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Congratulations! You are now a verified tour guide. You can start creating and managing tours.',
                    style: AppTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to create tour screen
                      Navigator.of(context).pushNamed('/guide/create-tour');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Create Your First Tour'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusTimeline() {
    final steps = [
      {
        'title': 'Submitted',
        'subtitle': 'Application received',
        'completed': true,
        'date': _verification!.submittedAt
      },
      {
        'title': 'Under Review',
        'subtitle': 'Admin reviewing documents',
        'completed': _verification!.status != VerificationStatus.pending,
        'date': null
      },
      {
        'title': 'Decision',
        'subtitle': _verification!.status == VerificationStatus.approved
            ? 'Approved'
            : _verification!.status == VerificationStatus.rejected
                ? 'Rejected'
                : 'Pending',
        'completed': _verification!.status != VerificationStatus.pending,
        'date': _verification!.reviewedAt
      },
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step['completed'] as bool
                        ? _getStatusColor()
                        : AppTheme.textSecondary.withOpacity(0.3),
                  ),
                  child: Icon(
                    step['completed'] as bool ? Icons.check : Icons.schedule,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: step['completed'] as bool
                        ? _getStatusColor()
                        : AppTheme.dividerColor,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['title'] as String,
                    style: AppTheme.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step['subtitle'] as String,
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.textSecondary),
                  ),
                  if (step['date'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(step['date'] as DateTime),
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title,
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(value, style: AppTheme.bodySmall),
      ),
    );
  }

  Color _getStatusColor() {
    switch (_verification!.status) {
      case VerificationStatus.approved:
        return AppTheme.successColor;
      case VerificationStatus.rejected:
        return AppTheme.errorColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getStatusIcon() {
    switch (_verification!.status) {
      case VerificationStatus.approved:
        return Icons.verified;
      case VerificationStatus.rejected:
        return Icons.error_outline;
      default:
        return Icons.schedule;
    }
  }

  String _getStatusTitle() {
    switch (_verification!.status) {
      case VerificationStatus.approved:
        return 'Verified Guide';
      case VerificationStatus.rejected:
        return 'Application Rejected';
      default:
        return 'Under Review';
    }
  }

  String _getStatusDescription() {
    switch (_verification!.status) {
      case VerificationStatus.approved:
        return 'Your application has been approved. You can now offer tours as a verified guide.';
      case VerificationStatus.rejected:
        return 'Your application was not approved. Please check the rejection reason below.';
      default:
        return 'Your application is being reviewed by our admin team. This usually takes 1-3 business days.';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
