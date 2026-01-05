import 'package:flutter/material.dart';
import 'package:tourmate_app/models/guide_verification_model.dart';
import '../../utils/app_theme.dart';

class AdminGuideVerificationScreen extends StatefulWidget {
  const AdminGuideVerificationScreen({super.key});

  @override
  State<AdminGuideVerificationScreen> createState() =>
      _AdminGuideVerificationScreenState();
}

class _AdminGuideVerificationScreenState
    extends State<AdminGuideVerificationScreen> {
  VerificationStatus _selectedFilter = VerificationStatus.pending;
  final TextEditingController _searchController = TextEditingController();

  // Mock verification data - replace with actual data fetching
  final List<GuideVerification> _verifications = [
    GuideVerification(
      id: '1',
      guideId: 'guide_001',
      guideName: 'Maria Santos',
      guideEmail: 'maria.santos@example.com',
      bio:
          'Experienced tour guide with 5+ years in Cebu tourism, specializing in historical and cultural tours.',
      idDocumentUrl: ['https://example.com/id_001.jpg'],
      lguDocumentUrl: ['https://example.com/lgu_001.jpg'],
      status: VerificationStatus.pending,
      submittedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    GuideVerification(
      id: '2',
      guideId: 'guide_002',
      guideName: 'Juan dela Cruz',
      guideEmail: 'juan.delacruz@example.com',
      bio:
          'Local guide born and raised in Bohol, expert in island hopping and adventure tours.',
      idDocumentUrl: ['https://example.com/id_002.jpg'],
      lguDocumentUrl: ['https://example.com/lgu_002.jpg'],
      status: VerificationStatus.pending,
      submittedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    GuideVerification(
      id: '3',
      guideId: 'guide_003',
      guideName: 'Ana Reyes',
      guideEmail: 'ana.reyes@example.com',
      bio:
          'Professional guide with tourism degree, specializes in eco-tourism and sustainable travel.',
      idDocumentUrl: ['https://example.com/id_003.jpg'],
      lguDocumentUrl: ['https://example.com/lgu_003.jpg'],
      status: VerificationStatus.approved,
      submittedAt: DateTime.now().subtract(const Duration(days: 10)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 8)),
      reviewedBy: 'Admin User',
    ),
    GuideVerification(
      id: '4',
      guideId: 'guide_004',
      guideName: 'Pedro Garcia',
      guideEmail: 'pedro.garcia@example.com',
      bio:
          'Mountain guide with extensive experience in hiking and outdoor activities.',
      idDocumentUrl: ['https://example.com/id_004.jpg'],
      lguDocumentUrl: ['https://example.com/lgu_004.jpg'],
      status: VerificationStatus.rejected,
      submittedAt: DateTime.now().subtract(const Duration(days: 7)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 6)),
      reviewedBy: 'Admin User',
      rejectionReason: 'LGU certificate expired',
    ),
  ];

  List<GuideVerification> get _filteredVerifications {
    return _verifications.where((verification) {
      final matchesFilter = verification.status == _selectedFilter;
      final matchesSearch = _searchController.text.isEmpty ||
          verification.guideName
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          verification.guideEmail
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Guide Verification',
                style: AppTheme.headlineLarge,
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_filteredVerifications.length} ${_selectedFilter.name}',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Review and approve tour guide verification applications',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 32),

          // Filters and Search
          Row(
            children: [
              // Status Filter
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<VerificationStatus>(
                  value: _selectedFilter,
                  underline: Container(),
                  items: VerificationStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(_capitalizeFirst(status.name)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedFilter = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Search
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search guides...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Statistics Cards
          Row(
            children: [
              _buildStatCard('Total', _verifications.length, Icons.people),
              const SizedBox(width: 16),
              _buildStatCard(
                  'Pending',
                  _verifications
                      .where((v) => v.status == VerificationStatus.pending)
                      .length,
                  Icons.pending),
              const SizedBox(width: 16),
              _buildStatCard(
                  'Approved',
                  _verifications
                      .where((v) => v.status == VerificationStatus.approved)
                      .length,
                  Icons.check_circle,
                  color: AppTheme.successColor),
              const SizedBox(width: 16),
              _buildStatCard(
                  'Rejected',
                  _verifications
                      .where((v) => v.status == VerificationStatus.rejected)
                      .length,
                  Icons.cancel,
                  color: AppTheme.errorColor),
            ],
          ),
          const SizedBox(height: 24),

          // Verifications Table
          Expanded(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Guide')),
                    DataColumn(label: Text('Submitted')),
                    DataColumn(label: Text('Documents')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _filteredVerifications.map((verification) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                verification.guideName,
                                style: AppTheme.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                verification.guideEmail,
                                style: AppTheme.bodySmall
                                    .copyWith(color: AppTheme.textSecondary),
                              ),
                              if (verification.bio != null &&
                                  verification.bio!.length > 50)
                                Text(
                                  '${verification.bio!.substring(0, 50)}...',
                                  style: AppTheme.bodySmall
                                      .copyWith(color: AppTheme.textSecondary),
                                ),
                            ],
                          ),
                        ),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_formatDate(verification.submittedAt)),
                              if (verification.reviewedAt != null)
                                Text(
                                  'Reviewed: ${_formatDate(verification.reviewedAt!)}',
                                  style: AppTheme.bodySmall
                                      .copyWith(color: AppTheme.successColor),
                                ),
                            ],
                          ),
                        ),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.description,
                                      size: 16, color: AppTheme.primaryColor),
                                  const SizedBox(width: 4),
                                  Text('ID Document',
                                      style: AppTheme.bodySmall),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.verified_user,
                                      size: 16, color: AppTheme.accentColor),
                                  const SizedBox(width: 4),
                                  Text('LGU Certificate',
                                      style: AppTheme.bodySmall),
                                ],
                              ),
                            ],
                          ),
                        ),
                        DataCell(_buildStatusChip(verification.status)),
                        DataCell(
                          verification.status == VerificationStatus.pending
                              ? Row(
                                  children: [
                                    TextButton(
                                      onPressed: () => _showReviewDialog(
                                          context, verification, true),
                                      child: const Text('Approve'),
                                      style: TextButton.styleFrom(
                                          foregroundColor:
                                              AppTheme.successColor),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () => _showReviewDialog(
                                          context, verification, false),
                                      child: const Text('Reject'),
                                      style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.errorColor),
                                    ),
                                  ],
                                )
                              : TextButton(
                                  onPressed: () =>
                                      _showDetailsDialog(context, verification),
                                  child: const Text('View Details'),
                                ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon,
      {Color? color}) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color ?? AppTheme.primaryColor, size: 24),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: AppTheme.headlineSmall.copyWith(
                  color: color ?? AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(VerificationStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case VerificationStatus.pending:
        color = AppTheme.accentColor;
        icon = Icons.pending;
        break;
      case VerificationStatus.approved:
        color = AppTheme.successColor;
        icon = Icons.check_circle;
        break;
      case VerificationStatus.rejected:
        color = AppTheme.errorColor;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            _capitalizeFirst(status.name),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(
      BuildContext context, GuideVerification verification, bool approve) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(approve ? 'Approve Verification' : 'Reject Verification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to ${approve ? 'approve' : 'reject'} ${verification.guideName}\'s verification?',
              ),
              if (!approve) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Rejection Reason (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _processReview(verification, approve, reasonController.text);
              },
              style: TextButton.styleFrom(
                foregroundColor:
                    approve ? AppTheme.successColor : AppTheme.errorColor,
              ),
              child: Text(approve ? 'Approve' : 'Reject'),
            ),
          ],
        );
      },
    );
  }

  void _showDetailsDialog(
      BuildContext context, GuideVerification verification) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${verification.guideName} - Verification Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Email', verification.guideEmail),
                _buildDetailRow(
                    'Submitted', _formatDate(verification.submittedAt)),
                if (verification.reviewedAt != null)
                  _buildDetailRow(
                      'Reviewed', _formatDate(verification.reviewedAt!)),
                if (verification.reviewedBy != null)
                  _buildDetailRow('Reviewed By', verification.reviewedBy!),
                if (verification.rejectionReason != null)
                  _buildDetailRow(
                      'Rejection Reason', verification.rejectionReason!),
                const SizedBox(height: 16),
                if (verification.bio != null) ...[
                  const Text('Bio:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(verification.bio!),
                  const SizedBox(height: 16),
                ],
                const Text('Documents:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (verification.idDocumentUrl != null)
                  _buildDocumentLink(
                      'ID Document', verification.idDocumentUrl!),
                if (verification.lguDocumentUrl != null)
                  _buildDocumentLink(
                      'LGU Certificate', verification.lguDocumentUrl!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildDocumentLink(String label, List<String> urls) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.link, size: 16),
          const SizedBox(width: 8),
          Text('$label: '),
          TextButton(
            onPressed: () {
              // TODO: Open document URL
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening $label')),
              );
            },
            child: Text('View Document (${urls.length})'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
        ],
      ),
    );
  }

  void _processReview(
      GuideVerification verification, bool approve, String? reason) {
    // TODO: Update verification status in database
    // TODO: Send notification to guide
    // TODO: Update user role if approved

    final newStatus =
        approve ? VerificationStatus.approved : VerificationStatus.rejected;
    final message = approve
        ? '${verification.guideName} has been approved as a verified guide!'
        : '${verification.guideName} verification has been rejected.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: approve ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );

    // Update local state (in real app, this would be handled by state management)
    // TODO: Implement proper state management for verification updates
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _capitalizeFirst(String text) {
    return text[0].toUpperCase() + text.substring(1);
  }
}
