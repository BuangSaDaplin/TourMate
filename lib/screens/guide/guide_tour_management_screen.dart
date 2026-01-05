import 'package:flutter/material.dart';
import 'package:tourmate_app/models/tour_model.dart';
import '../../utils/app_theme.dart';
import 'create_tour_screen.dart';

class GuideTourManagementScreen extends StatefulWidget {
  const GuideTourManagementScreen({super.key});

  @override
  State<GuideTourManagementScreen> createState() =>
      _GuideTourManagementScreenState();
}

class _GuideTourManagementScreenState extends State<GuideTourManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';

  final List<String> _statusOptions = ['All', 'Active', 'Draft', 'Suspended'];

  // Mock tour data - replace with actual data fetching for current guide
  final List<TourModel> _guideTours = [
    TourModel(
      id: '1',
      title: 'Kawasan Falls Canyoneering Adventure',
      description:
          'Experience the thrill of jumping, swimming, and trekking through the stunning Kawasan Falls canyon.',
      price: 2500.0,
      category: ['Adventure'],
      maxParticipants: 12,
      currentParticipants: 8,
      startTime: DateTime.now().add(const Duration(days: 7)),
      endTime: DateTime.now().add(const Duration(days: 7, hours: 8)),
      meetingPoint: 'Badian Town Center',
      mediaURL: ['kawasan1.jpg', 'kawasan2.jpg', 'kawasan3.jpg'],
      createdBy: 'current_guide_id', // This would be the actual guide ID
      shared: true,
      itinerary: [
        {'time': '08:00', 'activity': 'Meet at Badian Town Center'},
        {'time': '09:00', 'activity': 'Safety briefing and equipment'},
        {'time': '10:00', 'activity': 'Begin canyoneering adventure'},
        {'time': '16:00', 'activity': 'Return and farewell'}
      ],
      status: 'active',
      duration: 8,
      languages: ['English'],
      specializations: ['Hiking', 'Snorkeling'],
    ),
    TourModel(
      id: '2',
      title: 'Cebu City Historical Walking Tour',
      description:
          'Explore the rich history of Cebu City, from Magellan\'s Cross to Fort San Pedro.',
      price: 1200.0,
      category: ['Historical'],
      maxParticipants: 15,
      currentParticipants: 0,
      startTime: DateTime.now().add(const Duration(days: 14)),
      endTime: DateTime.now().add(const Duration(days: 14, hours: 4)),
      meetingPoint: 'Magellan\'s Cross',
      mediaURL: ['cebu_history1.jpg'],
      createdBy: 'current_guide_id',
      shared: true,
      itinerary: [
        {'time': '09:00', 'activity': 'Start at Magellan\'s Cross'},
        {'time': '10:00', 'activity': 'Visit Fort San Pedro'},
        {'time': '11:00', 'activity': 'Explore Basilica del Santo Niño'},
        {'time': '12:00', 'activity': 'Tour ends'}
      ],
      status: 'draft',
      duration: 4,
      languages: ['English', 'Cebuano'],
      specializations: ['History', 'Local Culture'],
    ),
  ];

  List<TourModel> get _filteredTours {
    return _guideTours.where((tour) {
      final matchesStatus = _selectedStatus == 'All' ||
          tour.status == _selectedStatus.toLowerCase();
      final matchesSearch = _searchController.text.isEmpty ||
          tour.title
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          tour.description
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Tours'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateTour(),
            tooltip: 'Create New Tour',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search my tours...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    underline: Container(),
                    items: _statusOptions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedStatus = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Stats Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatCard(
                    'Total Tours', _guideTours.length.toString(), Icons.tour),
                const SizedBox(width: 12),
                _buildStatCard(
                    'Active',
                    _guideTours
                        .where((t) => t.status == 'active')
                        .length
                        .toString(),
                    Icons.check_circle,
                    color: AppTheme.successColor),
                const SizedBox(width: 12),
                _buildStatCard(
                    'Draft',
                    _guideTours
                        .where((t) => t.status == 'draft')
                        .length
                        .toString(),
                    Icons.edit_note,
                    color: AppTheme.accentColor),
              ],
            ),
          ),

          // Tours List
          Expanded(
            child: _filteredTours.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredTours.length,
                    itemBuilder: (context, index) {
                      return _buildTourCard(_filteredTours[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateTour(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon,
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
                value,
                style: AppTheme.headlineSmall.copyWith(
                  color: color ?? AppTheme.primaryColor,
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

  Widget _buildTourCard(TourModel tour) {
    final duration = tour.endTime.difference(tour.startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showTourOptions(tour),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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

                        // Category and Status
                        Row(
                          children: [
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
                            const SizedBox(width: 8),
                            _buildStatusChip(tour.status),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Price and Duration
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
                            Icon(Icons.access_time,
                                size: 16, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${hours}h ${minutes}m',
                              style: AppTheme.bodySmall
                                  .copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Participants
                        Text(
                          '${tour.currentParticipants}/${tour.maxParticipants} participants',
                          style: AppTheme.bodySmall
                              .copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  // Menu Button
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, tour),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy),
                            SizedBox(width: 8),
                            Text('Duplicate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Quick Actions
              Row(
                children: [
                  if (tour.status == 'draft')
                    TextButton.icon(
                      onPressed: () => _publishTour(tour),
                      icon: const Icon(Icons.publish),
                      label: const Text('Publish'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppTheme.successColor),
                    ),
                  if (tour.status == 'active')
                    TextButton.icon(
                      onPressed: () => _viewBookings(tour),
                      icon: const Icon(Icons.people),
                      label: Text('${tour.currentParticipants} Bookings'),
                    ),
                  const Spacer(),
                  Text(
                    'Created ${_formatDate(tour.startTime)}',
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'active':
        color = AppTheme.successColor;
        icon = Icons.check_circle;
        break;
      case 'draft':
        color = AppTheme.accentColor;
        icon = Icons.edit_note;
        break;
      case 'suspended':
        color = AppTheme.errorColor;
        icon = Icons.block;
        break;
      default:
        color = AppTheme.textSecondary;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.capitalize(),
            style: AppTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
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
            Icons.tour_outlined,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No tours found',
            style:
                AppTheme.headlineMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first tour to get started',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateTour(),
            icon: const Icon(Icons.add),
            label: const Text('Create Tour'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateTour() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTourScreen()),
    ).then((_) => setState(() {})); // Refresh list after creating
  }

  void _showTourOptions(TourModel tour) {
    // Could show detailed view or quick actions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected: ${tour.title}')),
    );
  }

  void _handleMenuAction(String action, TourModel tour) {
    switch (action) {
      case 'edit':
        _editTour(tour);
        break;
      case 'duplicate':
        _duplicateTour(tour);
        break;
      case 'delete':
        _deleteTour(tour);
        break;
    }
  }

  void _editTour(TourModel tour) {
    // TODO: Navigate to edit tour screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit tour: ${tour.title}')),
    );
  }

  void _duplicateTour(TourModel tour) {
    // TODO: Create duplicate tour
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Duplicated: ${tour.title}')),
    );
  }

  void _deleteTour(TourModel tour) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Tour'),
          content: Text(
              'Are you sure you want to delete "${tour.title}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Delete tour from database
                setState(() {
                  _guideTours.remove(tour);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted: ${tour.title}')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _publishTour(TourModel tour) {
    // TODO: Update tour status to active
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Published: ${tour.title}')),
    );
  }

  void _viewBookings(TourModel tour) {
    // TODO: Navigate to bookings for this tour
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View bookings for: ${tour.title}')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
