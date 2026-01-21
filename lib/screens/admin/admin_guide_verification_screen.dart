import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourmate_app/models/guide_verification_model.dart';
import 'package:tourmate_app/models/user_model.dart';
import 'package:tourmate_app/services/database_service.dart';
import 'package:tourmate_app/services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';

class AdminGuideVerificationScreen extends StatefulWidget {
  const AdminGuideVerificationScreen({super.key});

  @override
  State<AdminGuideVerificationScreen> createState() =>
      _AdminGuideVerificationScreenState();
}

class _AdminGuideVerificationScreenState
    extends State<AdminGuideVerificationScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  List<GuideVerification> _verifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  VerificationStatus _selectedFilter = VerificationStatus.pending;
  final TextEditingController _searchController = TextEditingController();

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
  void initState() {
    super.initState();
    _loadVerifications();
  }

  Future<void> _loadVerifications() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final verifications = await _databaseService.getAllGuideVerifications();

      setState(() {
        _verifications = verifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load verifications: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: AppTheme.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadVerifications,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

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
                              if (verification.status ==
                                  VerificationStatus.pending) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () =>
                                      _showDetailsDialog(context, verification),
                                  child: const Text('View Details'),
                                  style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero),
                                ),
                              ],
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
    if (approve) {
      _showAssignDocumentsDialog(context, verification);
    } else {
      final TextEditingController reasonController = TextEditingController();

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Reject Verification'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Are you sure you want to reject ${verification.guideName}\'s verification?',
                ),
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _processReview(verification, false, reasonController.text);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: const Text('Reject'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showAssignDocumentsDialog(
      BuildContext context, GuideVerification verification) {
    final List<String> selectedCertifications = [];
    final List<String> selectedLguDocuments = [];

    final List<String> certificationOptions = [
      'DOT Accredited Tour Guide',
      'TESDA Tourism Certificate',
      'Eco-Tourism Certification',
      'Adventure Guide Certification',
      'First Aid / CPR',
      'Language Certification',
    ];

    final List<String> lguDocumentOptions = [
      'Barangay Clearance',
      'Mayor\'s Permit',
      'Police Clearance',
      'NBI Clearance',
      'Health Certificate',
      'LGU Tour Guide ID',
      'Tourism Office Registration',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Assign Verified Documents'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select the verified documents for ${verification.guideName}:',
                      style: AppTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Certifications:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...certificationOptions.map((cert) => CheckboxListTile(
                          title: Text(cert, style: AppTheme.bodySmall),
                          value: selectedCertifications.contains(cert),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedCertifications.add(cert);
                              } else {
                                selectedCertifications.remove(cert);
                              }
                            });
                          },
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                        )),
                    const SizedBox(height: 16),
                    const Text(
                      'LGU Documents:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...lguDocumentOptions.map((doc) => CheckboxListTile(
                          title: Text(doc, style: AppTheme.bodySmall),
                          value: selectedLguDocuments.contains(doc),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedLguDocuments.add(doc);
                              } else {
                                selectedLguDocuments.remove(doc);
                              }
                            });
                          },
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                        )),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _processApprovalWithDocuments(verification,
                        selectedCertifications, selectedLguDocuments);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.successColor,
                  ),
                  child: const Text('Approve'),
                ),
              ],
            );
          },
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
            onPressed: () async {
              if (urls.isNotEmpty) {
                final Uri url = Uri.parse(urls.first);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not open $label')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No $label available')),
                );
              }
            },
            child: Text('View Document (${urls.length})'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
        ],
      ),
    );
  }

  Future<void> _processApprovalWithDocuments(GuideVerification verification,
      List<String> certifications, List<String> lguDocuments) async {
    try {
      // Update user's certifications and LGU documents
      await _databaseService.updateUserField(
          verification.guideId, 'certifications', certifications);
      await _databaseService.updateUserField(
          verification.guideId, 'lguDocuments', lguDocuments);

      // Process the approval
      await _processReview(verification, true, null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign documents: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _processReview(
      GuideVerification verification, bool approve, String? reason) async {
    try {
      final newStatus =
          approve ? VerificationStatus.approved : VerificationStatus.rejected;

      // Update status in database
      await _databaseService.updateGuideVerificationStatus(
        verification.id,
        newStatus,
        'Admin User', // TODO: Get actual admin user name
        rejectionReason: reason,
      );

      // Update user status if approved
      if (approve) {
        await _databaseService.updateUserField(
            verification.guideId, 'status', UserStatus.approved.index);
      }

      // Update local state
      setState(() {
        final index = _verifications.indexWhere((v) => v.id == verification.id);
        if (index != -1) {
          _verifications[index] = verification.copyWith(
            status: newStatus,
            reviewedAt: DateTime.now(),
            reviewedBy: 'Admin User',
            rejectionReason: reason,
          );
        }
      });

      final message = approve
          ? '${verification.guideName} has been approved as a verified guide!'
          : '${verification.guideName} verification has been rejected.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              approve ? AppTheme.successColor : AppTheme.errorColor,
        ),
      );

      // Create notification for admin
      final currentAdmin = FirebaseAuth.instance.currentUser;
      if (currentAdmin != null) {
        final adminNotification = approve
            ? _notificationService.createGuideVerificationApprovedNotification(
                userId: currentAdmin.uid,
                guideName: verification.guideName,
              )
            : _notificationService.createGuideVerificationRejectedNotification(
                userId: currentAdmin.uid,
                guideName: verification.guideName,
                reason: reason ?? 'No reason provided',
              );

        await _notificationService.createNotification(adminNotification);
      }

      // TODO: Send notification to guide
      // TODO: Update user role if approved
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update verification: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _capitalizeFirst(String text) {
    return text[0].toUpperCase() + text.substring(1);
  }
}
