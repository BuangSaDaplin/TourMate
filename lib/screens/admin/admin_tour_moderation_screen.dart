import 'package:flutter/material.dart';
import 'package:tourmate_app/models/tour_model.dart';
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

  // Mock tour data with moderation status - replace with actual data fetching
  final List<Map<String, dynamic>> _toursForModeration = [
    {
      'tour': TourModel(
        id: '1',
        title: 'Inappropriate Content Tour',
        description:
            'This tour contains inappropriate content that violates community guidelines.',
        price: 1500.0,
        category: ['Adventure'],
        maxParticipants: 10,
        currentParticipants: 2,
        startTime: DateTime.now().add(const Duration(days: 5)),
        endTime: DateTime.now().add(const Duration(days: 5, hours: 6)),
        meetingPoint: 'Meeting Point',
        mediaURL: ['inappropriate1.jpg', 'inappropriate2.jpg'],
        createdBy: 'guide_001',
        shared: true,
        itinerary: [],
        status: 'suspended',
        duration: 6,
        languages: ['English'],
        specializations: ['Adventure'],
      ),
      'guideName': 'John Doe',
      'guideEmail': 'john@example.com',
      'moderationStatus': 'Pending Review',
      'reports': 3,
      'reportedReasons': ['Inappropriate content', 'Misleading description'],
      'submittedAt': DateTime.now().subtract(const Duration(days: 2)),
      'lastReviewed': null,
    },
    {
      'tour': TourModel(
        id: '2',
        title: 'Family-Friendly Beach Tour',
        description:
            'A wonderful family-friendly tour to pristine beaches with activities for all ages.',
        price: 2000.0,
        category: ['Beach'],
        maxParticipants: 15,
        currentParticipants: 8,
        startTime: DateTime.now().add(const Duration(days: 10)),
        endTime: DateTime.now().add(const Duration(days: 10, hours: 8)),
        meetingPoint: 'Beach Resort',
        mediaURL: ['beach1.jpg', 'beach2.jpg', 'beach3.jpg'],
        createdBy: 'guide_002',
        shared: true,
        itinerary: [],
        status: 'active',
        duration: 8,
        languages: ['English', 'Spanish'],
        specializations: ['Beach Activities', 'Family Tours'],
      ),
      'guideName': 'Jane Smith',
      'guideEmail': 'jane@example.com',
      'moderationStatus': 'Approved',
      'reports': 0,
      'reportedReasons': [],
      'submittedAt': DateTime.now().subtract(const Duration(days: 30)),
      'lastReviewed': DateTime.now().subtract(const Duration(days: 25)),
    },
    {
      'tour': TourModel(
        id: '3',
        title: 'Reported Tour - Safety Concerns',
        description:
            'This tour has been reported for safety concerns and needs review.',
        price: 1800.0,
        category: ['Adventure'],
        maxParticipants: 8,
        currentParticipants: 0,
        startTime: DateTime.now().add(const Duration(days: 15)),
        endTime: DateTime.now().add(const Duration(days: 15, hours: 5)),
        meetingPoint: 'Adventure Base',
        mediaURL: ['adventure1.jpg'],
        createdBy: 'guide_003',
        shared: true,
        itinerary: [],
        status: 'active',
        duration: 5,
        languages: ['English'],
        specializations: ['Adventure', 'Hiking'],
      ),
      'guideName': 'Mike Johnson',
      'guideEmail': 'mike@example.com',
      'moderationStatus': 'Pending Review',
      'reports': 5,
      'reportedReasons': [
        'Safety concerns',
        'Inadequate equipment',
        'Unqualified guide'
      ],
      'submittedAt': DateTime.now().subtract(const Duration(days: 7)),
      'lastReviewed': null,
    },
  ];

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
            child: _filteredTours.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _filteredTours.length,
                    itemBuilder: (context, index) {
                      return _buildTourModerationCard(_filteredTours[index]);
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
    // TODO: Navigate to detailed tour view for moderation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing details for: ${tourData['tour'].title}')),
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
      Map<String, dynamic> tourData, String action, String reason) {
    // TODO: Update tour moderation status in database
    // TODO: Send notification to guide
    // TODO: Log moderation action

    final message = action == 'approve'
        ? 'Tour "${tourData['tour'].title}" has been approved'
        : action == 'suspend'
            ? 'Tour "${tourData['tour'].title}" has been suspended'
            : 'Tour "${tourData['tour'].title}" is under review';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            action == 'approve' ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );

    // Update local state (in real app, this would be handled by state management)
    setState(() {
      tourData['moderationStatus'] =
          action == 'approve' ? 'Approved' : 'Suspended';
      tourData['lastReviewed'] = DateTime.now();
    });
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
