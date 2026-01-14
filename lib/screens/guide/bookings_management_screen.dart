import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../models/booking_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../models/message_model.dart';
import '../messaging/chat_screen.dart';
import '../itinerary/itinerary_screen.dart';
import '../../services/itinerary_service.dart';
import '../../models/itinerary_model.dart';
import '../../models/tour_model.dart';
import '../tour/tour_details_screen.dart';

class BookingsManagementScreen extends StatefulWidget {
  final int initialTabIndex;

  const BookingsManagementScreen({super.key, this.initialTabIndex = 0});

  @override
  State<BookingsManagementScreen> createState() =>
      _BookingsManagementScreenState();
}

class _BookingsManagementScreenState extends State<BookingsManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final ItineraryService _itineraryService = ItineraryService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: 'Confirmed'),
              Tab(text: 'Requests'),
              Tab(text: 'History'),
            ],
          ),
        ),
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildConfirmedTab(),
              _buildRequestsTab(),
              _buildHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmedTab() {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      return Center(
        child: Text(
          'Please log in to view confirmed bookings',
          style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
        ),
      );
    }

    return StreamBuilder<List<BookingModel>>(
      stream: _db.getBookingsByGuideStream(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                  'No confirmed bookings yet',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your confirmed bookings will appear here',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        final bookings = snapshot.data!
            .where((booking) =>
                booking.status.index == 1 ||
                booking.status.index == 2 ||
                booking.status.index == 3)
            .toList();
        if (bookings.isEmpty) {
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
                  'No confirmed bookings yet',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your confirmed bookings will appear here',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _buildRequestCardFromBooking(booking);
          },
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      return Center(
        child: Text(
          'Please log in to view booking requests',
          style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
        ),
      );
    }

    return StreamBuilder<List<BookingModel>>(
      stream: _db.getBookingsByGuideStream(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 64,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No booking requests yet',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your booking requests will appear here',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        final bookings = snapshot.data!
            .where((booking) => booking.status.index == 0)
            .toList();
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _buildRequestCardFromBooking(booking);
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      return Center(
        child: Text(
          'Please log in to view booking history',
          style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
        ),
      );
    }

    return StreamBuilder<List<BookingModel>>(
      stream: _db.getBookingsByGuideStream(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No booking history yet',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Completed and cancelled bookings will appear here',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        final bookings = snapshot.data!
            .where((booking) =>
                booking.status.index == 4 || booking.status.index == 5)
            .toList();
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No booking history yet',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Completed and cancelled bookings will appear here',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _buildHistoryCardFromBooking(booking);
          },
        );
      },
    );
  }

  Widget _buildRequestCardFromBooking(BookingModel booking) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(booking.touristId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration,
            child: const Center(child: Text('Error loading tourist details')),
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final touristName =
            userData?['displayName'] ?? userData?['name'] ?? 'Unknown User';

        // Convert BookingModel to Map for compatibility with existing methods
        final request = {
          'id': booking.id,
          'tourId': booking.tourId,
          'touristId': booking.touristId,
          'touristName': touristName,
          'tourTitle': booking.tourTitle,
          'date': booking.tourStartDate.toString().split(' ')[0], // Format date
          'participants': booking.numberOfParticipants,
          'totalAmount': booking.totalPrice.toInt(),
          'status': booking.status.name, // Convert enum to string
          'message': booking.specialRequests ?? 'No special requests',
          'duration': booking.duration,
        };

        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Request Header
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  request['touristName'][0],
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['touristName'],
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      request['tourTitle'],
                      style: AppTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  _showItineraryDialog(request);
                },
                icon: const Icon(Icons.map, size: 20),
                tooltip: 'View Itinerary',
                color: AppTheme.primaryColor,
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Feature coming soon!'),
                    ),
                  );
                },
                icon: const Icon(Icons.location_on, size: 20),
                tooltip: 'View Map',
                color: AppTheme.primaryColor,
              ),
              IconButton(
                onPressed: () => _showBookingDetailsDialog(request),
                icon: const Icon(Icons.visibility, size: 20),
                tooltip: 'View Details',
                color: AppTheme.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Booking Details
          _buildDetailRow('Date', request['date']),
          _buildDetailRow('Participants', '${request['participants']} people'),
          if (request['duration'] != null)
            _buildDetailRow('Duration', '${request['duration']} Hours'),
          _buildDetailRow('Total Amount', '₱${request['totalAmount']}'),
          const SizedBox(height: 12),

          // Status indicator for all bookings
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(request['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _getStatusColor(request['status']), width: 1),
            ),
            child: Text(
              _getStatusDisplayText(request['status']),
              style: TextStyle(
                color: _getStatusColor(request['status']),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons - Different based on status
          if (request['status'] == 'pending')
            _buildPendingBookingButtons(request)
          else if (request['status'] == 'confirmed' ||
              request['status'] == 'paid' ||
              request['status'] == 'inProgress')
            _buildActiveBookingButtons(request)
          else
            _buildAcceptedBookingButtons(request),
        ],
      ),
    );
  }

  Widget _buildPendingBookingButtons(Map<String, dynamic> request) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _showDeclineDialog(request);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: const BorderSide(color: AppTheme.errorColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Decline'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _acceptRequest(request);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Accept'),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveBookingButtons(Map<String, dynamic> request) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _showCancelDialog(request);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.cancel, size: 16),
                label: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _showEditDateDialog(request);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.edit_calendar, size: 16),
                label: const Text('Edit Schedule'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _showEditItineraryDialog(request);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentColor,
                  side: const BorderSide(color: AppTheme.accentColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text('Edit Itinerary'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _openChatWithTourist(request);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.message, size: 16),
                label: const Text('Message'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAcceptedBookingButtons(Map<String, dynamic> request) {
    return Column(
      children: [
        // Edit, Cancel, Complete buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _showEditDateDialog(request);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _showCancelDialog(request);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.cancel, size: 16),
                label: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _completeBooking(request);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Complete'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryCardFromBooking(BookingModel booking) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(booking.touristId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration,
            child: const Center(child: Text('Error loading tourist details')),
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final touristName =
            userData?['displayName'] ?? userData?['name'] ?? 'Unknown User';

        // Convert BookingModel to Map for compatibility with existing methods
        final historyBooking = {
          'id': booking.id,
          'touristName': touristName,
          'tourTitle': booking.tourTitle,
          'date': booking.tourStartDate.toString().split(' ')[0], // Format date
          'participants': booking.numberOfParticipants,
          'totalAmount': booking.totalPrice.toInt(),
          'status': booking.status.name, // Convert enum to string
          'duration': booking.duration,
          'rating': booking.rating, // Use actual rating from booking
          'review': booking.reviewContent, // Use actual review content
          'reviewStatus': booking.reviewStatus?.index, // Include review status
        };

        return _buildHistoryCard(historyBooking);
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Booking Header
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  booking['touristName'][0],
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['touristName'],
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      booking['tourTitle'],
                      style: AppTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  _showItineraryDialog(booking);
                },
                icon: const Icon(Icons.map, size: 20),
                tooltip: 'View Itinerary',
                color: AppTheme.primaryColor,
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Feature coming soon!'),
                    ),
                  );
                },
                icon: const Icon(Icons.location_on, size: 20),
                tooltip: 'View Map',
                color: AppTheme.primaryColor,
              ),
              IconButton(
                onPressed: () => _showBookingDetailsDialog(booking),
                icon: const Icon(Icons.visibility, size: 20),
                tooltip: 'View Details',
                color: AppTheme.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Booking Details
          _buildDetailRow('Date', booking['date']),
          _buildDetailRow('Participants', '${booking['participants']} people'),
          if (booking['duration'] != null)
            _buildDetailRow('Duration', '${booking['duration']} Hours'),
          _buildDetailRow('Total Amount', '₱${booking['totalAmount']}'),
          const SizedBox(height: 12),

          // Status indicator for history bookings
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(booking['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _getStatusColor(booking['status']), width: 1),
            ),
            child: Text(
              _getStatusDisplayText(booking['status']),
              style: TextStyle(
                color: _getStatusColor(booking['status']),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (booking['rating'] != null && booking['rating'] > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Rating: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < booking['rating'].round()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${booking['rating'].toStringAsFixed(1)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                // Lower right corner - View Feedback button
                TextButton(
                  onPressed: () {
                    _showFeedbackDialog(booking);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View Feedback',
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Text(
              'No rating yet',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)
                : AppTheme.bodyMedium,
          ),
          Text(
            value,
            style: isTotal
                ? AppTheme.headlineSmall.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  )
                : AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFA726); // Orange
      case 'confirmed':
        return const Color(0xFF42A5F5); // Blue
      case 'paid':
        return const Color(0xFF66BB6A); // Green
      case 'inProgress':
        return const Color(0xFF26A69A); // Teal
      case 'completed':
        return const Color(0xFF4CAF50); // Dark Green
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFE53935); // Red
      case 'refunded':
        return const Color(0xFF8D6E63); // Brown
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending Approval';
      case 'confirmed':
        return 'Confirmed - Payment Required';
      case 'paid':
        return 'Paid - Ready to Go';
      case 'inProgress':
        return 'Tour in Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case 'refunded':
        return 'Refunded';
      default:
        return 'Unknown';
    }
  }

  void _showItineraryDialog(Map<String, dynamic> booking) async {
    try {
      // Get the current booking to access itinerary information
      final currentBooking = await _db.getBooking(booking['id']);
      if (currentBooking == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking not found')),
        );
        return;
      }

      ItineraryModel? itinerary;

      // Try to get existing itinerary if booking has itineraryId
      if (currentBooking.itineraryId != null) {
        itinerary =
            await _itineraryService.getItinerary(currentBooking.itineraryId!);
      }

      // If no itinerary exists, try to get the tour and generate one
      if (itinerary == null) {
        final tour = await _db.getTour(currentBooking.tourId);
        if (tour != null) {
          itinerary = await _itineraryService.generateItineraryFromBooking(
              currentBooking, tour);
        }
      }

      if (itinerary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load itinerary')),
        );
        return;
      }

      // Navigate to itinerary screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ItineraryScreen(itinerary: itinerary!),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load itinerary: $e')),
      );
    }
  }

  void _showFeedbackDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${booking['tourTitle']} - Tourist Feedback'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tourist: ${booking['touristName']}',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Rating: ${booking['rating']}.0/5.0',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Review:',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getReviewDisplayText(booking),
                    style: AppTheme.bodyMedium,
                  ),
                ),
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

  void _showDeclineDialog(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Decline Request'),
          content: Text(
              'Are you sure you want to decline the request from ${request['touristName']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Update booking status to rejected
                  await _db.updateBookingStatus(
                    request['id'],
                    BookingStatus.rejected,
                  );

                  // Get current user (guide) name for notification
                  final currentUser = _authService.getCurrentUser();
                  String guideName = 'Guide';
                  if (currentUser != null) {
                    final userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser.uid)
                        .get();
                    final userData = userDoc.data();
                    guideName = userData?['displayName'] ??
                        userData?['name'] ??
                        'Guide';
                  }

                  // Send notification to tourist
                  final notification =
                      _notificationService.createBookingRejectedNotification(
                    userId: request['touristId'],
                    tourTitle: request['tourTitle'],
                    guideName: guideName,
                  );
                  await _notificationService.createNotification(notification);

                  Navigator.pop(context);
                  _showSnackBar('Request declined');
                } catch (e) {
                  _showSnackBar('Failed to decline request: ${e.toString()}');
                }
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
              child: const Text('Decline'),
            ),
          ],
        );
      },
    );
  }

  void _acceptRequest(Map<String, dynamic> request) async {
    try {
      // Get the current booking
      final booking = await _db.getBooking(request['id']);
      if (booking == null) {
        _showSnackBar('Booking not found');
        return;
      }

      // Update booking status to confirmed
      final updatedBooking = BookingModel(
        tourTitle: booking.tourTitle,
        id: booking.id,
        tourId: booking.tourId,
        touristId: booking.touristId,
        guideId: booking.guideId,
        bookingDate: booking.bookingDate,
        tourStartDate: booking.tourStartDate,
        numberOfParticipants: booking.numberOfParticipants,
        totalPrice: booking.totalPrice,
        status: BookingStatus.confirmed, // Changed from pending to confirmed
        specialRequests: booking.specialRequests,
        cancellationReason: booking.cancellationReason,
        cancelledAt: booking.cancelledAt,
        confirmedAt: DateTime.now(), // Set confirmed timestamp
        paidAt: booking.paidAt,
        completedAt: booking.completedAt,
        paymentDetails: booking.paymentDetails,
        participantNames: booking.participantNames,
        contactNumber: booking.contactNumber,
        emergencyContact: booking.emergencyContact,
        duration: booking.duration,
      );

      // Update in database
      await _db.updateBooking(updatedBooking);

      // Send notification to tourist
      final touristNotification = NotificationModel(
        id: 'booking_accept_${booking.id}_${DateTime.now().millisecondsSinceEpoch}',
        userId: booking.touristId,
        title: 'Booking Request Accepted',
        message:
            'Your booking request for "${booking.tourTitle}" has been accepted. Please proceed with payment.',
        type: NotificationType.booking,
        priority: NotificationPriority.normal,
        data: {'bookingId': booking.id, 'tourTitle': booking.tourTitle},
        createdAt: DateTime.now(),
      );
      await _notificationService.createNotification(touristNotification);

      // Send notification to guide
      final currentUser = _authService.getCurrentUser();
      if (currentUser != null) {
        final guideNotification =
            _notificationService.createBookingAcceptedNotification(
          userId: currentUser.uid,
          tourTitle: booking.tourTitle,
          touristName: request['touristName'],
        );
        await _notificationService.createNotification(guideNotification);
      }

      // Show success message
      _showSnackBar('Request accepted successfully!');
    } catch (e) {
      _showSnackBar('Failed to accept request: ${e.toString()}');
    }
  }

  void _showEditDateDialog(Map<String, dynamic> request) {
    // Parse current date from request (format: YYYY-MM-DD)
    DateTime selectedDate = DateTime.parse(request['date']);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Tour Date'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: AppTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Current tourist: ${request['touristName']}\nTour: ${request['tourTitle']}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      // Get the current booking
                      final booking = await _db.getBooking(request['id']);
                      if (booking == null) {
                        _showSnackBar('Booking not found');
                        return;
                      }
                      // Update booking with new date
                      final updatedBooking = BookingModel(
                        tourTitle: booking.tourTitle,
                        id: booking.id,
                        tourId: booking.tourId,
                        touristId: booking.touristId,
                        guideId: booking.guideId,
                        bookingDate: booking.bookingDate,
                        tourStartDate: selectedDate,
                        numberOfParticipants: booking.numberOfParticipants,
                        totalPrice: booking.totalPrice,
                        status: booking.status,
                        specialRequests: booking.specialRequests,
                        cancellationReason: booking.cancellationReason,
                        cancelledAt: booking.cancelledAt,
                        confirmedAt: booking.confirmedAt,
                        paidAt: booking.paidAt,
                        completedAt: booking.completedAt,
                        paymentDetails: booking.paymentDetails,
                        participantNames: booking.participantNames,
                        contactNumber: booking.contactNumber,
                        emergencyContact: booking.emergencyContact,
                        duration: booking.duration,
                      );
                      await _db.updateBooking(updatedBooking);

                      // Get current user (guide) name for notification
                      final currentUser = _authService.getCurrentUser();
                      String guideName = 'Guide';
                      if (currentUser != null) {
                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser.uid)
                            .get();
                        final userData = userDoc.data();
                        guideName = userData?['displayName'] ??
                            userData?['name'] ??
                            'Guide';
                      }

                      // Send notification to tourist about schedule update
                      final notification = _notificationService
                          .createTourScheduleUpdatedNotification(
                        userId: request['touristId'],
                        tourTitle: request['tourTitle'],
                        guideName: guideName,
                      );
                      await _notificationService
                          .createNotification(notification);

                      Navigator.pop(context);
                      _showSnackBar('Tour date updated successfully');
                    } catch (e) {
                      _showSnackBar('Failed to update date: ${e.toString()}');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Update Date'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCancelDialog(Map<String, dynamic> request) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please provide a reason for cancellation:',
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Cancellation Reason',
                  hintText: 'Enter reason for cancellation',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'This will cancel the booking for ${request['touristName']}\nTour: ${request['tourTitle']}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.errorColor,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Booking'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) {
                  _showSnackBar('Please provide a cancellation reason');
                  return;
                }
                try {
                  // Update booking status to cancelled
                  await _db.updateBookingStatus(
                    request['id'],
                    BookingStatus.cancelled,
                    cancellationReason: reasonController.text.trim(),
                    cancelledAt: DateTime.now(),
                  );

                  // Get current user (guide) name for notification
                  final currentUser = _authService.getCurrentUser();
                  String guideName = 'Guide';
                  if (currentUser != null) {
                    final userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser.uid)
                        .get();
                    final userData = userDoc.data();
                    guideName = userData?['displayName'] ??
                        userData?['name'] ??
                        'Guide';
                  }

                  // Send notification to tourist about booking cancellation
                  final notification = _notificationService
                      .createTourCancelledByGuideNotification(
                    userId: request['touristId'],
                    tourTitle: request['tourTitle'],
                    guideName: guideName,
                  );
                  await _notificationService.createNotification(notification);

                  Navigator.pop(context);
                  _showSnackBar('Booking cancelled successfully');
                } catch (e) {
                  _showSnackBar('Failed to cancel booking: ${e.toString()}');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Booking'),
            ),
          ],
        );
      },
    );
  }

  void _completeBooking(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Complete Booking'),
          content: Text(
            'Mark this booking as completed?\n\n'
            'Tourist: ${request['touristName']}\n'
            'Tour: ${request['tourTitle']}\n'
            'Date: ${request['date']}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Not Yet'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Update booking status to completed
                  await _db.updateBookingStatus(
                    request['id'],
                    BookingStatus.completed,
                    completedAt: DateTime.now(),
                  );

                  // Send notification to tourist about booking completion
                  final touristNotification =
                      _notificationService.createTourCompletedNotification(
                    userId: request['touristId'],
                    tourTitle: request['tourTitle'],
                  );
                  await _notificationService
                      .createNotification(touristNotification);

                  // Send notification to guide about booking completion
                  final currentUser = _authService.getCurrentUser();
                  if (currentUser != null) {
                    final guideNotification = _notificationService
                        .createTourCompletedForGuideNotification(
                      userId: currentUser.uid,
                      tourTitle: request['tourTitle'],
                      touristName: request['touristName'],
                    );
                    await _notificationService
                        .createNotification(guideNotification);
                  }

                  Navigator.pop(context);
                  _showSnackBar('Booking completed successfully!');
                } catch (e) {
                  _showSnackBar('Failed to complete booking: ${e.toString()}');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mark Complete'),
            ),
          ],
        );
      },
    );
  }

  void _openChatWithTourist(Map<String, dynamic> request) async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) return;

    try {
      // Get current user data
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      final currentUserName =
          currentUserData['displayName'] ?? currentUserData['name'] ?? 'Guide';

      // Get tourist data
      final touristDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(request['touristId'])
          .get();
      final touristData = touristDoc.data() as Map<String, dynamic>;
      final touristName =
          touristData['displayName'] ?? touristData['name'] ?? 'Tourist';

      // Create or get chat room
      final chatRoom = await _db.getOrCreateChatRoom(
        currentUserId: currentUser.uid,
        otherUserId: request['touristId'],
        currentUserName: currentUserName,
        otherUserName: touristName,
        currentUserRole: 'Guide',
        otherUserRole: 'Tourist',
        relatedTourId: request['tourId'],
      );

      if (chatRoom == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create chat room')),
        );
        return;
      }

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatRoom: chatRoom,
            currentUserId: currentUser.uid,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open chat: $e')),
      );
    }
  }

  void _shareItinerary(Map<String, dynamic> booking) async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      _showSnackBar('Please log in to share itinerary');
      return;
    }

    try {
      // Get or create chat room with tourist
      final touristDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(booking['touristId'])
          .get();
      final touristData = touristDoc.data() as Map<String, dynamic>;
      final touristName =
          touristData['displayName'] ?? touristData['name'] ?? 'Tourist';

      final chatRoom = await _db.getOrCreateChatRoom(
        currentUserId: currentUser.uid,
        otherUserId: booking['touristId'],
        currentUserName: currentUser.displayName ?? 'Guide',
        otherUserName: touristName,
        currentUserRole: 'Guide',
        otherUserRole: 'Tourist',
        relatedTourId: booking['tourId'],
      );

      if (chatRoom == null) {
        _showSnackBar('Failed to create chat room');
        return;
      }

      // Create itinerary message
      final itineraryMessage = MessageModel(
        id: '', // Will be generated by Firestore
        chatRoomId: chatRoom.id,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'Guide',
        senderRole: 'Guide',
        content:
            'Here\'s the itinerary for our ${booking['tourTitle']} tour:\n\n'
            'Day 1: Arrival & Check-in\n'
            '• 7:00 AM - Hotel pickup\n'
            '• 8:00 AM - Breakfast at local restaurant\n'
            '• 9:00 AM - Start of tour activities\n\n'
            'Day 2: Main Activities\n'
            '• 6:00 AM - Early morning departure\n'
            '• 8:00 AM - Main destination arrival\n'
            '• 12:00 PM - Lunch break\n'
            '• 3:00 PM - Return journey\n\n'
            'Day 3: Departure\n'
            '• 7:00 AM - Hotel checkout\n'
            '• 8:00 AM - Airport transfer\n'
            '• 10:00 AM - Flight departure',
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      // Send the message
      await _db.sendMessage(itineraryMessage);

      // Close the dialog and show success message
      Navigator.pop(context);
      _showSnackBar('Itinerary shared successfully');
    } catch (e) {
      _showSnackBar('Failed to share itinerary: ${e.toString()}');
    }
  }

  void _showEditItineraryDialog(Map<String, dynamic> request) async {
    // Get the current booking to access itinerary information
    final currentBooking = await _db.getBooking(request['id']);
    String currentItinerary = '';

    if (currentBooking != null &&
        currentBooking.specialRequests != null &&
        currentBooking.specialRequests!.isNotEmpty) {
      // Use the updated itinerary from specialRequests field
      currentItinerary = currentBooking.specialRequests!;
    } else {
      // Fallback to default itinerary
      currentItinerary = 'Day 1: Arrival & Check-in\n'
          '• 7:00 AM - Hotel pickup\n'
          '• 8:00 AM - Breakfast at local restaurant\n'
          '• 9:00 AM - Start of tour activities\n\n'
          'Day 2: Main Activities\n'
          '• 6:00 AM - Early morning departure\n'
          '• 8:00 AM - Main destination arrival\n'
          '• 12:00 PM - Lunch break\n'
          '• 3:00 PM - Return journey\n\n'
          'Day 3: Departure\n'
          '• 7:00 AM - Hotel checkout\n'
          '• 8:00 AM - Airport transfer\n'
          '• 10:00 AM - Flight departure';
    }

    final TextEditingController itineraryController = TextEditingController(
      text: currentItinerary,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Itinerary - ${request['tourTitle']}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tourist: ${request['touristName']}',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: itineraryController,
                  decoration: InputDecoration(
                    labelText: 'Itinerary Details',
                    hintText: 'Enter the detailed itinerary for this tour',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 12,
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Changes will be saved and the tourist will be notified.',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
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
                itineraryController.text = currentItinerary;
              },
              child: const Text('Revert Changes'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (itineraryController.text.trim().isEmpty) {
                  _showSnackBar('Please provide itinerary details');
                  return;
                }

                try {
                  // Get the current booking
                  final booking = await _db.getBooking(request['id']);
                  if (booking == null) {
                    _showSnackBar('Booking not found');
                    return;
                  }

                  // Update the itinerary in the specialRequests field
                  final updatedBooking = BookingModel(
                    tourTitle: booking.tourTitle,
                    id: booking.id,
                    tourId: booking.tourId,
                    touristId: booking.touristId,
                    guideId: booking.guideId,
                    itineraryId: booking.itineraryId,
                    bookingDate: booking.bookingDate,
                    tourStartDate: booking.tourStartDate,
                    numberOfParticipants: booking.numberOfParticipants,
                    totalPrice: booking.totalPrice,
                    status: booking.status,
                    specialRequests: itineraryController.text.trim(),
                    cancellationReason: booking.cancellationReason,
                    cancelledAt: booking.cancelledAt,
                    confirmedAt: booking.confirmedAt,
                    paidAt: booking.paidAt,
                    completedAt: booking.completedAt,
                    paymentDetails: booking.paymentDetails,
                    participantNames: booking.participantNames,
                    contactNumber: booking.contactNumber,
                    emergencyContact: booking.emergencyContact,
                    duration: booking.duration,
                    reviewContent: booking.reviewContent,
                    rating: booking.rating,
                    reviewCreatedAt: booking.reviewCreatedAt,
                    reviewerId: booking.reviewerId,
                    reviewerName: booking.reviewerName,
                    reviewModeratedAt: booking.reviewModeratedAt,
                    reviewModerateReason: booking.reviewModerateReason,
                    reviewStatus: booking.reviewStatus,
                  );

                  await _db.updateBooking(updatedBooking);

                  // Get current user (guide) name for notification
                  final currentUser = _authService.getCurrentUser();
                  String guideName = 'Guide';
                  if (currentUser != null) {
                    final userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser.uid)
                        .get();
                    final userData = userDoc.data();
                    guideName = userData?['displayName'] ??
                        userData?['name'] ??
                        'Guide';
                  }

                  // Send notification to tourist about itinerary update
                  final notification =
                      _notificationService.createItineraryUpdatedNotification(
                    userId: request['touristId'],
                    tourTitle: request['tourTitle'],
                    guideName: guideName,
                  );
                  await _notificationService.createNotification(notification);

                  Navigator.pop(context);
                  _showSnackBar('Itinerary updated successfully');
                } catch (e) {
                  _showSnackBar('Failed to update itinerary: ${e.toString()}');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update Itinerary'),
            ),
          ],
        );
      },
    );
  }

  void _showBookingDetailsDialog(Map<String, dynamic> booking) async {
    // Convert Map to BookingModel for compatibility with tourist side implementation
    final bookingModel = BookingModel(
      tourTitle: booking['tourTitle'] ?? '',
      id: booking['id'] ?? '',
      tourId: booking['tourId'] ?? '',
      touristId: booking['touristId'] ?? '',
      guideId: booking['guideId'] ?? '',
      bookingDate: DateTime.now(), // Not available in map, use current time
      tourStartDate:
          DateTime.parse(booking['date'] ?? DateTime.now().toString()),
      numberOfParticipants: booking['participants'] ?? 1,
      totalPrice: (booking['totalAmount'] ?? 0).toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == (booking['status'] ?? 'pending'),
        orElse: () => BookingStatus.pending,
      ),
      specialRequests: booking['message'],
      duration: booking['duration'],
      reviewContent: booking['review'],
      rating: booking['rating']?.toDouble(),
      reviewStatus: booking['reviewStatus'] != null
          ? ReviewSubmissionStatus.values[booking['reviewStatus']]
          : null,
    );

    // Fetch tour data for location and price
    TourModel? tour;
    try {
      tour = await _db.getTour(bookingModel.tourId);
    } catch (e) {
      // Handle error silently, tour will be null
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Booking Details'),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.7,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Booked Tour Information
                  Text(
                    'Booked Tour Information',
                    style: AppTheme.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TourDetailsScreen(
                            tourId: bookingModel.tourId,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bookingModel.tourTitle,
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tour?.meetingPoint ?? 'Location not available',
                                style: AppTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₱${tour?.price.toStringAsFixed(0) ?? bookingModel.totalPrice.toStringAsFixed(0)} per person',
                            style: AppTheme.bodyLarge.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Booking Details
                  Text(
                    'Booking Details',
                    style: AppTheme.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date
                  _buildDetailRow(
                    'Tour Date',
                    '${bookingModel.tourStartDate.day}/${bookingModel.tourStartDate.month}/${bookingModel.tourStartDate.year}',
                  ),
                  const SizedBox(height: 8),

                  // Time (assuming start time from tour or default)
                  _buildDetailRow(
                    'Tour Start',
                    tour?.startTime != null
                        ? '${tour!.startTime.hour}:${tour.startTime.minute.toString().padLeft(2, '0')}'
                        : 'Time not specified',
                  ),
                  const SizedBox(height: 8),

                  // Duration
                  _buildDetailRow(
                    'Duration',
                    '${bookingModel.duration ?? tour?.duration ?? 0} Hours',
                  ),
                  const SizedBox(height: 8),

                  // Number of Participants
                  _buildDetailRow(
                    'Number of Participants',
                    '${bookingModel.numberOfParticipants}',
                  ),
                  const SizedBox(height: 8),

                  // Participant's Names
                  if (bookingModel.participantNames != null &&
                      bookingModel.participantNames!.isNotEmpty)
                    _buildDetailRow(
                      'Participant\'s Names',
                      bookingModel.participantNames!.join(', '),
                    ),
                  if (bookingModel.participantNames != null &&
                      bookingModel.participantNames!.isNotEmpty)
                    const SizedBox(height: 8),

                  // Total Amount
                  _buildDetailRow(
                    'Total Amount',
                    '₱${bookingModel.totalPrice.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 16),

                  // Booking Summary
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Booking Summary',
                              style: AppTheme.headlineSmall),
                          const SizedBox(height: 16),
                          if (tour != null &&
                              tour.inclusionPrices.isNotEmpty) ...[
                            ...() {
                              // Calculate total from current inclusion prices
                              double calculatedTotal =
                                  tour!.inclusionPrices.entries.fold(
                                      0.0,
                                      (sum, entry) =>
                                          sum +
                                          entry.value *
                                              bookingModel
                                                  .numberOfParticipants);

                              // Only show breakdown if it matches the booking total
                              if (calculatedTotal == bookingModel.totalPrice) {
                                return [
                                  const SizedBox(height: 8),
                                  ...tour.inclusionPrices.entries.map(
                                    (entry) => _buildSummaryRow(
                                      entry.key,
                                      '₱${(entry.value * bookingModel.numberOfParticipants).toStringAsFixed(2)}',
                                    ),
                                  ),
                                  const Divider(),
                                ];
                              } else {
                                return [
                                  const SizedBox(height: 8),
                                  Text(
                                    'Price breakdown not available (tour details may have changed)',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const Divider(),
                                ];
                              }
                            }(),
                          ],
                          _buildSummaryRow(
                            'Total Amount',
                            '₱${bookingModel.totalPrice.toStringAsFixed(2)}',
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  String _getReviewDisplayText(Map<String, dynamic> booking) {
    // Get the review status from the booking
    final reviewStatusRaw = booking['reviewStatus'];

    // Debug logging
    print(
        'DEBUG: reviewStatusRaw = $reviewStatusRaw, type = ${reviewStatusRaw?.runtimeType}');

    if (reviewStatusRaw == null) {
      return 'No review provided.';
    }

    // Convert to int if necessary
    int reviewStatus;
    if (reviewStatusRaw is int) {
      reviewStatus = reviewStatusRaw;
    } else if (reviewStatusRaw is String) {
      reviewStatus = int.tryParse(reviewStatusRaw) ?? -1;
    } else {
      return 'No review provided.';
    }

    print('DEBUG: converted reviewStatus = $reviewStatus');

    switch (reviewStatus) {
      case 1: // approved
        return booking['review'] ?? 'No review provided.';
      case 0: // pending
        return 'Review is pending approval.';
      case 2: // rejected
        return 'Review has been moderated by admin.';
      default:
        print('DEBUG: Hit default case with reviewStatus = $reviewStatus');
        return 'No review provided.';
    }
  }
}
