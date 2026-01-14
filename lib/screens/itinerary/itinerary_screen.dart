import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tourmate_app/models/itinerary_model.dart';
import 'package:tourmate_app/services/itinerary_service.dart';
import 'package:tourmate_app/services/auth_service.dart';
import 'package:tourmate_app/services/email_service.dart';
import 'package:tourmate_app/services/user_profile_service.dart';
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
    final itemsForDate = _itinerary.getItemsForDate(_selectedDate);
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
      body: Column(
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
      ),
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
                  onTap: null,
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
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${DateFormat('HH:mm').format(item.startTime)} - ${DateFormat('HH:mm').format(item.startTime.add(const Duration(minutes: 15)))} (${item.title})',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            if (item.cost != null && item.cost! > 0) ...[
                              const SizedBox(width: 16),
                              Icon(
                                Icons.attach_money,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '\$${item.cost!.toStringAsFixed(2)}',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
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

  void _addNewActivity() {
    // Navigate to add activity screen
    // This would open a form to create a new activity
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add activity functionality coming soon!')),
    );
  }

  void _editActivity(ItineraryItemModel activity) {
    // Navigate to edit activity screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit activity functionality coming soon!')),
    );
  }

  void _showActivityOptions(ItineraryItemModel activity) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Activity Options',
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Activity'),
              onTap: () {
                Navigator.pop(context);
                _editActivity(activity);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleActivityCompletion(
      ItineraryItemModel activity, bool isCompleted) async {
    try {
      await _itineraryService.toggleActivityCompletion(
        _itinerary.id,
        activity.id,
        isCompleted,
      );

      setState(() {
        // Update local state
        final updatedItems = _itinerary.items.map((item) {
          if (item.id == activity.id) {
            return ItineraryItemModel(
              id: item.id,
              title: item.title,
              description: item.description,
              type: item.type,
              startTime: item.startTime,
              endTime: item.endTime,
              location: item.location,
              address: item.address,
              cost: item.cost,
              notes: item.notes,
              imageUrl: item.imageUrl,
              isCompleted: isCompleted,
              order: item.order,
              metadata: item.metadata,
            );
          }
          return item;
        }).toList();

        _itinerary = ItineraryModel(
          id: _itinerary.id,
          userId: _itinerary.userId,
          title: _itinerary.title,
          description: _itinerary.description,
          startDate: _itinerary.startDate,
          endDate: _itinerary.endDate,
          status: _itinerary.status,
          items: updatedItems,
          coverImageUrl: _itinerary.coverImageUrl,
          isPublic: _itinerary.isPublic,
          shareCode: _itinerary.shareCode,
          createdAt: _itinerary.createdAt,
          updatedAt: DateTime.now(),
          relatedBookingId: _itinerary.relatedBookingId,
          relatedTourId: _itinerary.relatedTourId,
          settings: _itinerary.settings,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update activity: $e')),
      );
    }
  }

  void _deleteActivity(ItineraryItemModel activity) async {
    try {
      await _itineraryService.removeActivityFromItinerary(
          _itinerary.id, activity.id);

      setState(() {
        _itinerary = ItineraryModel(
          id: _itinerary.id,
          userId: _itinerary.userId,
          title: _itinerary.title,
          description: _itinerary.description,
          startDate: _itinerary.startDate,
          endDate: _itinerary.endDate,
          status: _itinerary.status,
          items:
              _itinerary.items.where((item) => item.id != activity.id).toList(),
          coverImageUrl: _itinerary.coverImageUrl,
          isPublic: _itinerary.isPublic,
          shareCode: _itinerary.shareCode,
          createdAt: _itinerary.createdAt,
          updatedAt: DateTime.now(),
          relatedBookingId: _itinerary.relatedBookingId,
          relatedTourId: _itinerary.relatedTourId,
          settings: _itinerary.settings,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete activity: $e')),
      );
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        _shareItinerary();
        break;
    }
  }

  void _shareItinerary() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Itinerary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the email address to share this itinerary:'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'recipient@example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter an email address')),
                );
                return;
              }

              // Validate email format and ensure it's a Gmail address
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(email)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter a valid email address')),
                );
                return;
              }
              if (!email.endsWith('@gmail.com')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Please enter a valid Gmail address (must end with @gmail.com)')),
                );
                return;
              }

              Navigator.of(context).pop(); // Close dialog

              try {
                // Here you would integrate with your email service
                // For now, we'll show a success message
                await _sendItineraryByEmail(email);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Itinerary sent to $email successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to send itinerary: $e')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendItineraryByEmail(String email) async {
    try {
      // Get the current user's name for the email
      final currentUserModel = await _authService.getCurrentUserModel();
      String senderName = currentUserModel?.displayName ?? 'TourMate User';

      // Send the itinerary via email
      final success = await _emailService.sendItineraryEmail(
        recipientEmail: email,
        itinerary: _itinerary,
        senderName: senderName,
      );

      if (!success) {
        throw Exception('Failed to send email');
      }

      print('Successfully sent itinerary "${_itinerary.title}" to $email');
    } catch (e) {
      print('Error sending itinerary email: $e');
      throw e; // Re-throw to be handled by the calling method
    }
  }
}
