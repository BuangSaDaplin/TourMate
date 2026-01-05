import 'package:flutter/material.dart';
import 'package:tourmate_app/models/tour_model.dart';
import 'package:tourmate_app/models/user_model.dart';
import 'package:tourmate_app/services/database_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';

class AdminTourModerationScreen extends StatefulWidget {
  const AdminTourModerationScreen({super.key});

  @override
  State<AdminTourModerationScreen> createState() =>
      _AdminTourModerationScreenState();
}

class _AdminTourModerationScreenState extends State<AdminTourModerationScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _selectedSort = 'Newest';
  bool _isLoading = true;
  final DatabaseService _databaseService = DatabaseService();

  final List<String> _filterOptions = [
    'All',
    'Pending Review',
    'Approved',
    'Suspended',
    'Reported'
  ];
  final List<String> _sortOptions = [
    'Newest',
    'Oldest',
    'Most Reported',
    'Guide Name'
  ];

  List<Map<String, dynamic>> _toursForModeration = [];

  List<Map<String, dynamic>> get _filteredTours {
    return _toursForModeration.where((tourData) {
      final matchesFilter = _selectedFilter == 'All' ||
          tourData['moderationStatus'] == _selectedFilter;
      final matchesSearch = _searchController.text.isEmpty ||
          tourData['tour']
              .title
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          tourData['guideName']
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList()
      ..sort((a, b) {
        switch (_selectedSort) {
          case 'Oldest':
            return a['submittedAt'].compareTo(b['submittedAt']);
          case 'Most Reported':
            return (b['reports'] as int).compareTo(a['reports'] as int);
          case 'Guide Name':
            return a['guideName'].compareTo(b['guideName']);
          case 'Newest':
          default:
            return b['submittedAt'].compareTo(a['submittedAt']);
        }
      });
  }

  @override
  void initState() {
    super.initState();
    _fetchToursForModeration();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchToursForModeration() async {
    setState(() => _isLoading = true);
    try {
      final tours = await _databaseService.getAllTours();
      final List<Map<String, dynamic>> moderationData = [];

      for (final tour in tours) {
        final guide = await _databaseService.getUser(tour.createdBy);
        final guideName = guide?.displayName ?? 'Unknown Guide';
        final guideEmail = guide?.email ?? 'unknown@example.com';

        // Determine moderation status based on tour status
        String moderationStatus;
        if (tour.status == 'active') {
          moderationStatus = 'Approved';
        } else if (tour.status == 'suspended') {
          moderationStatus = 'Suspended';
        } else {
          moderationStatus = 'Pending Review';
        }

        moderationData.add({
          'tour': tour,
          'guideName': guideName,
          'guideEmail': guideEmail,
          'moderationStatus': moderationStatus,
          'reports': 0, // TODO: Implement reports functionality
          'reportedReasons':
              <String>[], // TODO: Implement reports functionality
          'submittedAt':
              DateTime.now(), // TODO: Add createdAt field to TourModel
          'lastReviewed': null,
        });
      }

      setState(() {
        _toursForModeration = moderationData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tours: $e')),
      );
    }
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
                'Tour Moderation',
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
                  '${_filteredTours.length} tours',
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
            'Review and moderate tour listings for compliance and quality',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 32),

          // Search and Filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tours or guides...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  underline: Container(),
                  items: _filterOptions.map((filter) {
                    return DropdownMenuItem(
                      value: filter,
                      child: Text(filter),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedSort,
                  underline: Container(),
                  items: _sortOptions.map((sort) {
                    return DropdownMenuItem(
                      value: sort,
                      child: Text(sort),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedSort = value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Statistics Cards
          Row(
            children: [
              _buildStatCard(
                  'Pending Review',
                  _toursForModeration
                      .where((t) => t['moderationStatus'] == 'Pending Review')
                      .length,
                  Icons.pending,
                  AppTheme.accentColor),
              const SizedBox(width: 16),
              _buildStatCard(
                  'Approved',
                  _toursForModeration
                      .where((t) => t['moderationStatus'] == 'Approved')
                      .length,
                  Icons.check_circle,
                  AppTheme.successColor),
              const SizedBox(width: 16),
              _buildStatCard(
                  'Suspended',
                  _toursForModeration
                      .where((t) => t['moderationStatus'] == 'Suspended')
                      .length,
                  Icons.block,
                  AppTheme.errorColor),
              const SizedBox(width: 16),
              _buildStatCard(
                  'Total Reports',
                  _toursForModeration.fold(
                      0, (sum, t) => sum + (t['reports'] as int)),
                  Icons.report,
                  AppTheme.primaryColor),
            ],
          ),
          const SizedBox(height: 24),

          // Tours List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTours.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _filteredTours.length,
                        itemBuilder: (context, index) {
                          return _buildTourModerationCard(
                              _filteredTours[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: AppTheme.headlineSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTourModerationCard(Map<String, dynamic> tourData) {
    final tour = tourData['tour'] as TourModel;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and reports
            Row(
              children: [
                _buildStatusChip(tourData['moderationStatus']),
                const Spacer(),
                if (tourData['reports'] > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.report,
                            size: 14, color: AppTheme.errorColor),
                        const SizedBox(width: 4),
                        Text(
                          '${tourData['reports']} reports',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Tour Image and Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tour Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: AssetImage(
                          'assets/images/${tour.mediaURL.isNotEmpty ? tour.mediaURL[0] : 'default_tour.jpg'}'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Tour Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tour.title,
                        style: AppTheme.bodyLarge
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Guide Info
                      Row(
                        children: [
                          Icon(Icons.person,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            tourData['guideName'],
                            style: AppTheme.bodyMedium,
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.email,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tourData['guideEmail'],
                              style: AppTheme.bodySmall
                                  .copyWith(color: AppTheme.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Price and Category
                      Row(
                        children: [
                          Text(
                            '₱${tour.price.toStringAsFixed(0)}',
                            style: AppTheme.bodyLarge.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tour.category.isNotEmpty
                                  ? tour.category[0]
                                  : 'No Category',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Dates
                      Text(
                        'Submitted: ${_formatDate(tourData['submittedAt'])}',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Reported Reasons (if any)
            if (tourData['reportedReasons'].isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reported Issues:',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...tourData['reportedReasons'].map<Widget>((reason) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.error,
                                size: 14, color: AppTheme.errorColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                reason,
                                style: AppTheme.bodySmall
                                    .copyWith(color: AppTheme.errorColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewTourDetails(tourData),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                if (tourData['moderationStatus'] == 'Pending Review')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showModerationDialog(context, tourData, 'approve'),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (tourData['moderationStatus'] == 'Pending Review')
                  const SizedBox(width: 12),
                if (tourData['moderationStatus'] == 'Pending Review')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showModerationDialog(context, tourData, 'suspend'),
                      icon: const Icon(Icons.block),
                      label: const Text('Suspend'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (tourData['moderationStatus'] != 'Pending Review')
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showModerationDialog(context, tourData, 'review'),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Review Again'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'Approved':
        color = AppTheme.successColor;
        icon = Icons.check_circle;
        break;
      case 'Suspended':
        color = AppTheme.errorColor;
        icon = Icons.block;
        break;
      case 'Pending Review':
      default:
        color = AppTheme.accentColor;
        icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'All tours are moderated',
            style:
                AppTheme.headlineMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'No tours require moderation at this time',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _viewTourDetails(Map<String, dynamic> tourData) {
    final tour = tourData['tour'] as TourModel;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${tour.title} - Tour Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Guide Name', tourData['guideName']),
                _buildDetailRow('Guide Email', tourData['guideEmail']),
                _buildDetailRow('Status', tourData['moderationStatus']),
                _buildDetailRow('Price', '₱${tour.price.toStringAsFixed(0)}'),
                _buildDetailRow(
                    'Category',
                    tour.category.isNotEmpty
                        ? tour.category.join(', ')
                        : 'No Category'),
                _buildDetailRow(
                    'Max Participants', tour.maxParticipants.toString()),
                _buildDetailRow('Current Participants',
                    tour.currentParticipants.toString()),
                _buildDetailRow('Duration', '${tour.duration} hours'),
                _buildDetailRow('Meeting Point', tour.meetingPoint),
                _buildDetailRow(
                    'Languages',
                    tour.languages.isNotEmpty
                        ? tour.languages.join(', ')
                        : 'Not specified'),
                _buildDetailRow(
                    'Specializations',
                    tour.specializations.isNotEmpty
                        ? tour.specializations.join(', ')
                        : 'Not specified'),
                _buildDetailRow(
                    'Submitted', _formatDate(tourData['submittedAt'])),
                if (tourData['lastReviewed'] != null)
                  _buildDetailRow(
                      'Last Reviewed', _formatDate(tourData['lastReviewed'])),
                const SizedBox(height: 16),
                const Text('Description:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(tour.description),
                const SizedBox(height: 16),
                if (tour.itinerary.isNotEmpty) ...[
                  const Text('Itinerary:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...tour.itinerary.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item['time']}: ${item['activity']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          if (item['description'] != null &&
                              item['description']!.isNotEmpty)
                            Text(item['description']!,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
                const Text('Documents/Media:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (tour.mediaURL.isNotEmpty)
                  _buildMediaLink('Tour Media', tour.mediaURL)
                else
                  const Text('No documents/media submitted'),
                if (tourData['reportedReasons'].isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Reported Issues:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 8),
                  ...tourData['reportedReasons'].map<Widget>((reason) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.error, size: 14, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reason,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
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

  void _showModerationDialog(
      BuildContext context, Map<String, dynamic> tourData, String action) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(action == 'approve'
              ? 'Approve Tour'
              : action == 'suspend'
                  ? 'Suspend Tour'
                  : 'Review Tour'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to ${action == 'approve' ? 'approve' : action == 'suspend' ? 'suspend' : 'review'} "${tourData['tour'].title}"?',
              ),
              if (action == 'suspend') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Suspension Reason (Required)',
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
                _processModeration(tourData, action, reasonController.text);
              },
              style: TextButton.styleFrom(
                foregroundColor: action == 'approve'
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
              ),
              child: Text(action == 'approve'
                  ? 'Approve'
                  : action == 'suspend'
                      ? 'Suspend'
                      : 'Review'),
            ),
          ],
        );
      },
    );
  }

  void _processModeration(
      Map<String, dynamic> tourData, String action, String reason) async {
    try {
      final tour = tourData['tour'] as TourModel;
      String newStatus;

      if (action == 'approve') {
        newStatus = 'active';
      } else if (action == 'suspend') {
        newStatus = 'suspended';
      } else {
        newStatus = 'pending';
      }

      await _databaseService.updateTourStatus(tour.id, newStatus);

      final message = action == 'approve'
          ? 'Tour "${tour.title}" has been approved'
          : action == 'suspend'
              ? 'Tour "${tour.title}" has been suspended'
              : 'Tour "${tour.title}" is under review';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              action == 'approve' ? AppTheme.successColor : AppTheme.errorColor,
        ),
      );

      // Update local state
      setState(() {
        tourData['moderationStatus'] =
            action == 'approve' ? 'Approved' : 'Suspended';
        tourData['lastReviewed'] = DateTime.now();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing moderation: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildMediaLink(String label, List<String> urls) {
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
            child: Text('View Media (${urls.length})'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
        ],
      ),
    );
  }
}
