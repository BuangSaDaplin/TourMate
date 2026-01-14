import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tourmate_app/models/itinerary_model.dart';
import 'package:tourmate_app/services/itinerary_service.dart';
import 'package:tourmate_app/services/auth_service.dart';
import 'package:tourmate_app/services/email_service.dart';
import 'package:tourmate_app/services/user_profile_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';

class ItineraryScreen extends StatefulWidget {
  final ItineraryModel itinerary;

  const ItineraryScreen({super.key, required this.itinerary});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  final ItineraryService _itineraryService = ItineraryService();
  final AuthService _authService = AuthService();
  final EmailService _emailService = EmailService();
  final UserProfileService _userProfileService = UserProfileService();
  late ItineraryModel _itinerary;
  DateTime _selectedDate = DateTime.now();
  bool _isGuide = false;

  Future<bool> _isUserGuide(String userId) async {
    try {
      final userProfile =
          await _userProfileService.getCompleteUserProfile(userId);
      return userProfile?.role == 'guide';
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _itinerary = widget.itinerary;
    if (_itinerary.startDate.isBefore(DateTime.now()) &&
        _itinerary.endDate.isAfter(DateTime.now())) {
      _selectedDate = DateTime.now();
    } else {
      _selectedDate = _itinerary.startDate;
    }
    _loadUserRole();
  }

  @override
  void didUpdateWidget(ItineraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the parent widget passes a new itinerary (e.g. from a refresh),
    // update our local state to match it.
    if (widget.itinerary != oldWidget.itinerary) {
      setState(() {
        _itinerary = widget.itinerary;
        // Optional: Reset selected date if needed, or keep user's selection
        // _selectedDate = _itinerary.startDate;
      });
    }
  }

  Future<void> _loadUserRole() async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser != null) {
      _isGuide = await _isUserGuide(currentUser.uid);
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.getCurrentUser();
    final isOwner = _itinerary.userId == currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_itinerary.title),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Menu button for both tourists and guides
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Text('Share Itinerary'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('itineraries')
            .doc(widget.itinerary.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading data"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final liveData = snapshot.data!.data() as Map<String, dynamic>;
          _itinerary = ItineraryModel.fromMap(liveData);
          final itemsForDate = _itinerary.getItemsForDate(_selectedDate);

          return Column(
            children: [
              // Itinerary Header
              _buildItineraryHeader(),

              // Date Selector
              _buildDateSelector(),

              // Activities Timeline
              Expanded(
                child: itemsForDate.isEmpty
                    ? _buildEmptyState()
                    : _buildActivitiesTimeline(itemsForDate),
              ),
            ],
          );
        },
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton(
              onPressed: _addNewActivity,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildItineraryHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _itinerary.title,
                  style: AppTheme.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(_itinerary.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _itinerary.status.toString().split('.').last.toUpperCase(),
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _itinerary.description,
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final dates = <DateTime>[];
    for (int i = 0; i < _itinerary.totalDays; i++) {
      dates.add(_itinerary.startDate.add(Duration(days: i)));
    }

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;
          final itemsForDate = _itinerary.getItemsForDate(date);

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.dividerColor,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: AppTheme.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: AppTheme.headlineSmall.copyWith(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No activities planned',
            style: AppTheme.headlineSmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add activities to make your day memorable!',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesTimeline(List<ItineraryItemModel> items) {
    // Sort items by start time
    items.sort((a, b) => a.startTime.compareTo(b.startTime));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isLast = index == items.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            SizedBox(
              width: 60,
              child: Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: item.isCompleted ? Colors.green : item.typeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 60,
                      color: AppTheme.dividerColor,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                ],
              ),
            ),

            // Activity card
            Expanded(
              child: Card(
                margin: const EdgeInsets.only(bottom: 16, left: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () => _showActivityOptions(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              item.typeIcon,
                              color: item.typeColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.title,
                                style: AppTheme.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: AppTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),

                            /// THIS FIXES THE OVERFLOW
                            Expanded(
                              child: Text(
                                '${DateFormat('HH:mm').format(item.startTime)} - '
                                '${DateFormat('HH:mm').format(item.startTime.add(const Duration(minutes: 15)))} '
                                '(${item.title})',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                                softWrap: true,
                              ),
                            ),

                            if (item.cost != null && item.cost! > 0) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '₱${item.cost!.toStringAsFixed(2)}',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (item.location != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.location!,
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (item.notes != null && item.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.note,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.notes!,
                                    style: AppTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.typeDisplayName,
                            style: AppTheme.bodySmall.copyWith(
                              color: item.typeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(ItineraryStatus status) {
    switch (status) {
      case ItineraryStatus.draft:
        return Colors.grey;
      case ItineraryStatus.published:
        return AppTheme.primaryColor;
      case ItineraryStatus.completed:
        return Colors.green;
      case ItineraryStatus.archived:
        return Colors.blueGrey;
    }
  }

  String _getActivityTypeDisplayName(ActivityType type) {
    switch (type) {
      case ActivityType.tour:
        return 'Tour';
      case ActivityType.transportation:
        return 'Transportation';
      case ActivityType.accommodation:
        return 'Accommodation';
      case ActivityType.meal:
        return 'Meal';
      case ActivityType.attraction:
        return 'Attraction';
      case ActivityType.shopping:
        return 'Shopping';
      case ActivityType.rest:
        return 'Rest';
      case ActivityType.custom:
        return 'Custom';
    }
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'share':
        _shareItinerary();
        break;
    }
  }

  Future<void> _shareItinerary() async {
    try {
      await _emailService.sendItineraryEmail(
        itinerary: _itinerary,
        recipientEmail: '',
        senderName: '',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Itinerary shared successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share itinerary: $e')),
        );
      }
    }
  }

  Future<void> _addNewActivity() async {
    final result = await Navigator.pushNamed(
      context,
      '/add-activity',
      arguments: {
        'itineraryId': _itinerary.id,
        'date': _selectedDate,
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity added successfully!')),
      );
    }
  }

  void _showActivityOptions(ItineraryItemModel item) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Activity'),
                onTap: () {
                  Navigator.pop(context);
                  _editActivity(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Activity'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteActivity(item);
                },
              ),
              ListTile(
                leading: Icon(
                  item.isCompleted
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                ),
                title: Text(
                  item.isCompleted ? 'Mark as Incomplete' : 'Mark as Complete',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleActivityCompletion(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editActivity(ItineraryItemModel item) async {
    final result = await Navigator.pushNamed(
      context,
      '/edit-activity',
      arguments: {
        'itineraryId': _itinerary.id,
        'activityId': item.id,
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity updated successfully!')),
      );
    }
  }

  Future<void> _deleteActivity(ItineraryItemModel item) async {
    try {
      await _itineraryService.removeActivityFromItinerary(
          _itinerary.id, item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete activity: $e')),
        );
      }
    }
  }

  Future<void> _toggleActivityCompletion(ItineraryItemModel item) async {
    try {
      await _itineraryService.toggleActivityCompletion(
        _itinerary.id,
        item.id,
        !item.isCompleted,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              item.isCompleted
                  ? 'Activity marked as incomplete'
                  : 'Activity marked as complete',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update activity: $e')),
        );
      }
    }
  }

  Future<void> _exportItinerary() async {
    try {
      final pdfBytes =
          await _itineraryService.exportItineraryToPdf(_itinerary.id);
      // Implement PDF saving/exporting logic here
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Itinerary exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export itinerary: $e')),
        );
      }
    }
  }

  Future<void> _printItinerary() async {
    try {
      await _itineraryService.printItinerary(_itinerary.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Itinerary sent to printer!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to print itinerary: $e')),
        );
      }
    }
  }

  Future<void> _archiveItinerary() async {
    try {
      await _itineraryService.archiveItinerary(_itinerary.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Itinerary archived successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to archive itinerary: $e')),
        );
      }
    }
  }

  Future<void> _deleteItinerary() async {
    try {
      await _itineraryService.deleteItinerary(_itinerary.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Itinerary deleted successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete itinerary: $e')),
        );
      }
    }
  }
}
