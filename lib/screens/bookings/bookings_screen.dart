import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../services/payment_service.dart';
import '../../models/booking_model.dart';
import '../../models/payment_model.dart';
import '../../models/message_model.dart';
import '../../models/tour_model.dart';
import '../../models/user_model.dart';
import '../notifications/notification_screen.dart';
import '../messaging/chat_screen.dart';
import '../tour/tour_details_screen.dart';
import '../tour/tour_map_screen.dart';
import '../itinerary/itinerary_screen.dart';
import '../../services/itinerary_service.dart';
import '../../models/itinerary_model.dart';
import '../../data/cebu_graph_data.dart';
import '../../data/tour_spot_model.dart';

class BookingsScreen extends StatefulWidget {
  final int initialTab;

  const BookingsScreen({super.key, this.initialTab = 0});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  final PaymentService _paymentService = PaymentService();
  final ItineraryService _itineraryService = ItineraryService();

  Widget _compactIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return IconButton(
      icon: Icon(icon, size: 16),
      tooltip: tooltip,
      padding: EdgeInsets.zero, // ⬅ removes inner padding
      constraints: const BoxConstraints(), // ⬅ removes min size
      visualDensity: VisualDensity.compact, // ⬅ tighter touch area
      onPressed: onPressed,
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Bookings'),
        elevation: 0,
        actions: [
          StreamBuilder<int>(
            stream: FirebaseAuth.instance.currentUser != null
                ? _notificationService
                    .getUnreadCount(FirebaseAuth.instance.currentUser!.uid)
                : Stream.value(0),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                },
                tooltip: 'Notifications',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              // Handle language selection
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Language selection coming soon!'),
                ),
              );
            },
            tooltip: 'Language',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ongoing'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: _getCurrentUserBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading bookings: ${snapshot.error}'),
            );
          }

          final bookings = snapshot.data ?? [];

          final upcomingBookings = bookings
              .where(
                (booking) =>
                    booking.status != BookingStatus.completed &&
                    booking.status != BookingStatus.cancelled &&
                    booking.status != BookingStatus.rejected,
              )
              .toList();

          final pastBookings = bookings
              .where(
                (booking) =>
                    booking.status == BookingStatus.completed ||
                    booking.status == BookingStatus.cancelled ||
                    booking.status == BookingStatus.rejected,
              )
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildUpcomingBookings(upcomingBookings),
              _buildPastBookings(pastBookings),
            ],
          );
        },
      ),
    );
  }

  Stream<List<BookingModel>> _getCurrentUserBookings() {
    final user = _authService.getCurrentUser();
    if (user != null) {
      return _db.getBookingsByTouristStream(user.uid);
    }
    return Stream.value([]);
  }

  Widget _buildUpcomingBookings(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return _buildEmptyState(
        'No Upcoming Bookings',
        'Start exploring Cebu and book your next adventure!',
        Icons.calendar_today,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking, isUpcoming: true);
      },
    );
  }

  Widget _buildPastBookings(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return _buildEmptyState(
        'No Past Bookings',
        'Your completed tours will appear here',
        Icons.history,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking, isUpcoming: false);
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 50, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          Text(title, style: AppTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking, {required bool isUpcoming}) {
    final statusColor = booking.status == BookingStatus.confirmed
        ? AppTheme.successColor
        : booking.status == BookingStatus.pending
            ? Colors.orange
            : AppTheme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.confirmation_number,
                      size: 18,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Booking ${_formatBookingId(booking.id)}',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 0,
                  runSpacing: 2,
                  alignment: WrapAlignment.end,
                  children: [
                    _compactIconButton(
                      icon: Icons.schedule,
                      tooltip: 'View Itinerary',
                      onPressed: () => _showItineraryDialog(booking),
                    ),
                    if (isUpcoming)
                      _compactIconButton(
                        icon: Icons.location_on,
                        tooltip: 'View Map',
                        onPressed: () => _viewMapForBooking(booking),
                      ),
                    _compactIconButton(
                      icon: Icons.message,
                      tooltip: 'Message',
                      onPressed: () => _openChatWithGuide(booking),
                    ),
                    _compactIconButton(
                      icon: Icons.visibility,
                      tooltip: 'View Details',
                      onPressed: () => _showBookingDetailsDialog(booking),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Booking details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.tourTitle,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoItem(
                      Icons.calendar_today,
                      '${booking.tourStartDate.day}/${booking.tourStartDate.month}/${booking.tourStartDate.year}',
                    ),
                    const SizedBox(width: 24),
                    FutureBuilder<TourModel?>(
                      future: _db.getTour(booking.tourId),
                      builder: (context, snapshot) {
                        final tour = snapshot.data;
                        final startTime =
                            '${booking.tourStartDate.hour}:${booking.tourStartDate.minute.toString().padLeft(2, '0')}';
                        final endTime = tour != null
                            ? '${tour.endTime.hour}:${tour.endTime.minute.toString().padLeft(2, '0')}'
                            : '${booking.tourStartDate.add(Duration(hours: (booking.duration ?? 0).toInt())).hour}:${booking.tourStartDate.add(Duration(hours: (booking.duration ?? 0).toInt())).minute.toString().padLeft(2, '0')}';
                        return _buildInfoItem(
                          Icons.access_time,
                          '${booking.duration ?? 0} Hrs ($startTime to $endTime)',
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FutureBuilder<String>(
                      future: _getGuideName(booking.guideId),
                      builder: (context, snapshot) {
                        final guideName = snapshot.data ?? 'Loading...';
                        return _buildInfoItem(
                          Icons.person,
                          'Guide: $guideName',
                        );
                      },
                    ),
                    const SizedBox(width: 24),
                    _buildInfoItem(
                      Icons.people,
                      '${booking.numberOfParticipants} People',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Show pending payment confirmation for inProgress status
                if (booking.status == BookingStatus.inProgress) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'Pending payment confirmation',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Total: ₱${booking.totalPrice.toStringAsFixed(0)}',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isUpcoming) ...[
                      Flexible(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          alignment: WrapAlignment.end,
                          children: [
                            // Pending status: Only Cancel button
                            if (booking.status == BookingStatus.pending) ...[
                              TextButton(
                                onPressed: () {
                                  _showCancelDialog(booking);
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.errorColor,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ],
                            // Confirmed status (waiting for payment): Pay Now + Cancel
                            if (booking.status == BookingStatus.confirmed) ...[
                              TextButton(
                                onPressed: () {
                                  _showPaymentDialog(booking);
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                child: const Text('Pay Now'),
                              ),
                              TextButton(
                                onPressed: () {
                                  _showCancelReasonDialog(booking);
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.errorColor,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ],
                            // Paid status (ready to go): Complete + Cancel
                            if (booking.status == BookingStatus.paid) ...[
                              ElevatedButton(
                                onPressed: () {
                                  _showCompleteDialog(booking);
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(80, 36),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                child: const Text('Complete'),
                              ),
                              TextButton(
                                onPressed: () {
                                  _showCancelReasonDialog(booking);
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.errorColor,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ],
                            // In Progress status: Only Cancel (waiting for payment confirmation)
                            if (booking.status == BookingStatus.inProgress) ...[
                              TextButton(
                                onPressed: () {
                                  _showCancelReasonDialog(booking);
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.errorColor,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else ...[
                      Flexible(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (booking.rating != null) ...[
                                const Text(
                                  'Rating: ',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Row(
                                  children: List.generate(
                                    5,
                                    (index) => Icon(
                                      index < booking.rating!.round()
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${booking.rating!.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ] else ...[
                                const Text(
                                  'No rating yet',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: AppTheme.bodySmall),
      ],
    );
  }

  Future<String> _getGuideName(String? guideId) async {
    if (guideId == null) return 'Unknown';
    try {
      final user = await _db.getUser(guideId);
      return user?.displayName ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showCancelDialog(BookingModel booking) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: Text(
            'Are you sure you want to cancel your booking for ${booking.tourTitle}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _db.updateBookingStatus(
                    booking.id,
                    BookingStatus.cancelled,
                    cancelledAt: DateTime.now(),
                  );

                  // Create notification for booking cancellation by tourist
                  final currentUser = _authService.getCurrentUser();
                  if (currentUser != null) {
                    final notification = _notificationService
                        .createTourCancelledByTouristNotification(
                      userId: currentUser.uid,
                      tourTitle: booking.tourTitle,
                    );
                    await _notificationService.createNotification(notification);
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking cancelled successfully'),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel booking: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showCancelReasonDialog(BookingModel booking) async {
    final TextEditingController _reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for cancellation:'),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter reason...',
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
              onPressed: () async {
                try {
                  await _db.updateBookingStatus(
                    booking.id,
                    BookingStatus.cancelled,
                    cancellationReason: _reasonController.text.trim(),
                    cancelledAt: DateTime.now(),
                  );

                  // Create notification for booking cancellation by tourist
                  final currentUser = _authService.getCurrentUser();
                  if (currentUser != null) {
                    final notification = _notificationService
                        .createTourCancelledByTouristNotification(
                      userId: currentUser.uid,
                      tourTitle: booking.tourTitle,
                    );
                    await _notificationService.createNotification(notification);
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking cancelled successfully'),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel booking: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _showCompleteDialog(BookingModel booking) async {
    final TextEditingController _reviewController = TextEditingController();
    double _rating = 0;
    final currentUser = _authService.getCurrentUser();

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to complete booking')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Complete Booking'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Rate your experience:'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        onPressed: () {
                          setState(() {
                            _rating = index + 1.0;
                          });
                        },
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 25,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reviewController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Write a review...',
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
                  onPressed: () async {
                    if (_rating == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please provide a rating'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    try {
                      // Update booking status to completed
                      await _db.updateBookingStatus(
                        booking.id,
                        BookingStatus.completed,
                        completedAt: DateTime.now(),
                      );

                      // Save review data directly to booking document
                      await _db.updateBookingWithReview(
                        booking.id,
                        reviewContent: _reviewController.text.trim(),
                        rating: _rating,
                        reviewCreatedAt: DateTime.now(),
                        reviewerId: currentUser.uid,
                        reviewerName: currentUser.displayName ?? 'Tourist',
                        reviewStatus: ReviewSubmissionStatus.pending,
                      );

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Booking completed and review submitted',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to complete booking: $e'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showItineraryDialog(BookingModel booking) async {
    try {
      ItineraryModel? itinerary;

      // Try to get existing itinerary if booking has itineraryId
      if (booking.itineraryId != null) {
        itinerary = await _itineraryService.getItinerary(booking.itineraryId!);
      }

      // If no itinerary exists, try to get the tour and generate one
      if (itinerary == null) {
        final tour = await _db.getTour(booking.tourId);
        if (tour != null) {
          itinerary = await _itineraryService.generateItineraryFromBooking(
            booking,
            tour,
          );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load itinerary: $e')));
    }
  }

  void _showBookingDetailsDialog(BookingModel booking) async {
    // Fetch tour data for location and price
    TourModel? tour;
    try {
      tour = await _db.getTour(booking.tourId);
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
                          builder: (context) =>
                              TourDetailsScreen(tourId: booking.tourId),
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
                            booking.tourTitle,
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
                            '₱${tour?.price.toStringAsFixed(0) ?? booking.totalPrice.toStringAsFixed(0)} per person',
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
                    '${booking.tourStartDate.day}/${booking.tourStartDate.month}/${booking.tourStartDate.year}',
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
                    '${booking.duration ?? tour?.duration ?? 0} Hours',
                  ),
                  const SizedBox(height: 8),

                  // Number of Participants
                  _buildDetailRow(
                    'Number of Participants',
                    '${booking.numberOfParticipants}',
                  ),
                  const SizedBox(height: 8),

                  // Participant's Names
                  if (booking.participantNames != null &&
                      booking.participantNames!.isNotEmpty)
                    _buildDetailRow(
                      'Participant\'s Names',
                      booking.participantNames!.join(', '),
                    ),
                  if (booking.participantNames != null &&
                      booking.participantNames!.isNotEmpty)
                    const SizedBox(height: 8),

                  // Total Amount
                  _buildDetailRow(
                    'Total Amount',
                    '₱${booking.totalPrice.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 16),

                  // Booking Summary
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Booking Summary',
                            style: AppTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          if (tour != null &&
                              tour.inclusionPrices.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ...tour.inclusionPrices.entries.map(
                              (entry) => _buildSummaryRow(
                                entry.key,
                                '₱${(entry.value * booking.numberOfParticipants).toStringAsFixed(2)}',
                              ),
                            ),
                          ],
                          const Divider(),
                          _buildSummaryRow(
                            'Total Amount',
                            '₱${booking.totalPrice.toStringAsFixed(2)}',
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            '$label:',
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value, style: AppTheme.bodyMedium)),
      ],
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

  void _openChatWithGuide(BookingModel booking) async {
    if (booking.guideId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guide information not available')),
      );
      return;
    }

    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to message the guide')),
      );
      return;
    }

    try {
      // Get guide user data
      final guideUser = await _db.getUser(booking.guideId!);
      if (guideUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Guide not found')));
        return;
      }

      // Get or create chat room
      final chatRoom = await _db.getOrCreateChatRoom(
        currentUserId: currentUser.uid,
        otherUserId: guideUser.uid,
        currentUserName: currentUser.displayName ?? 'Tourist',
        otherUserName: guideUser.displayName ?? 'Guide',
        currentUserRole: 'Tourist',
        otherUserRole: guideUser.role ?? 'Guide',
        relatedBookingId: booking.id,
        relatedTourId: booking.tourId,
      );

      if (chatRoom != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatScreen(chatRoom: chatRoom, currentUserId: currentUser.uid),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to open chat')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening chat: $e')));
    }
  }

  void _viewMapForBooking(BookingModel booking) async {
    try {
      // Fetch the tour document using tourId
      final tour = await _db.getTour(booking.tourId);
      if (tour == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tour information not found')),
        );
        return;
      }

      // Get the meetingPoint from the tour
      final meetingPoint = tour.meetingPoint;
      if (meetingPoint.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meeting location not available on map'),
          ),
        );
        return;
      }

      // Find matching tour spot in cebu_graph_data
      TourSpot? matchingSpot;
      for (final spot in CebuGraphData.allSpots) {
        if (spot.name.toLowerCase() == meetingPoint.toLowerCase()) {
          matchingSpot = spot;
          break;
        }
      }

      if (matchingSpot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meeting location not available on map'),
          ),
        );
        return;
      }

      // Navigate to the map screen with the matched spot's id
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TourMapScreen(tourId: matchingSpot!.id),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading map: $e')));
    }
  }

  PaymentMethod _mapStringToPaymentMethod(String method) {
    switch (method) {
      case 'Credit Card':
        return PaymentMethod.creditCard;
      case 'GCash':
        return PaymentMethod.gcash;
      case 'PayMaya':
        return PaymentMethod.paymaya;
      case 'Bank Transfer':
        return PaymentMethod.bankTransfer;
      case 'Cash':
        return PaymentMethod.cash;
      default:
        return PaymentMethod.cash;
    }
  }

  String _formatBookingId(String id) {
    if (id.length <= 5) {
      return id;
    }
    return '${id.substring(0, 5)}...';
  }

  void _shareItinerary(BookingModel booking, String itineraryText) async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to share itinerary')),
      );
      return;
    }

    if (booking.guideId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guide information not available')),
      );
      return;
    }

    try {
      // Get or create chat room with guide
      final guideUser = await _db.getUser(booking.guideId!);
      if (guideUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Guide not found')));
        return;
      }

      final chatRoom = await _db.getOrCreateChatRoom(
        currentUserId: currentUser.uid,
        otherUserId: guideUser.uid,
        currentUserName: currentUser.displayName ?? 'Tourist',
        otherUserName: guideUser.displayName ?? 'Guide',
        currentUserRole: 'Tourist',
        otherUserRole: guideUser.role ?? 'Guide',
        relatedBookingId: booking.id,
        relatedTourId: booking.tourId,
      );

      if (chatRoom == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create chat room')),
        );
        return;
      }

      // Create itinerary message using the provided itinerary text
      final itineraryMessage = MessageModel(
        id: '', // Will be generated by Firestore
        chatRoomId: chatRoom.id,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'Tourist',
        senderRole: 'Tourist',
        content:
            'Here\'s the itinerary for our ${booking.tourTitle} tour:\n\n$itineraryText',
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      // Send the message
      await _db.sendMessage(itineraryMessage);

      // Close the dialog and show success message
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Itinerary shared successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to share itinerary: $e')));
    }
  }

  void _showPaymentDialog(BookingModel booking) {
    String selectedPaymentMethod = 'Cash';
    final TextEditingController _cardNumberController = TextEditingController();
    final TextEditingController _expiryController = TextEditingController();
    final TextEditingController _cvvController = TextEditingController();
    final TextEditingController _cardHolderController = TextEditingController();
    final TextEditingController _gcashNumberController =
        TextEditingController();
    final TextEditingController _referenceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Payment Methods'),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height *
                    0.7, // Limit height to 70% of screen
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Payment Method:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      // Payment method selection
                      Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text('Cash'),
                            value: 'Cash',
                            groupValue: selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() {
                                selectedPaymentMethod = value!;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('E-Wallet'),
                            value: 'E-Wallet',
                            groupValue: selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() {
                                selectedPaymentMethod = value!;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Payment form fields
                      if (selectedPaymentMethod == 'Cash') ...[
                        const Text(
                          'Cash Payment Instructions:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Select Cash as your payment method\n'
                          '• Pay the full amount in cash during the tour meetup\n'
                          '• The tour guide will collect the payment on behalf of the platform\n'
                          '• Platform commission is automatically recorded by the system\n'
                          '• A digital receipt will be issued after payment is confirmed\n'
                          '• For any payment concerns, please contact customer support',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Cash payments are settled through the platform’s internal tracking system.\n'
                          'Bookings remain subject to verification to ensure proper commission handling.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ] else if (selectedPaymentMethod == 'E-Wallet') ...[
                        FutureBuilder<UserModel?>(
                          future: _authService.getCurrentUser() != null
                              ? _db.getUser(_authService.getCurrentUser()!.uid)
                              : Future.value(null),
                          builder: (context, snapshot) {
                            final user = snapshot.data;
                            final eWalletBalance = user?.eWallet ?? 0.0;
                            final isSufficient =
                                eWalletBalance >= booking.totalPrice;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'E-Wallet Payment:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSufficient
                                          ? Colors.green
                                          : Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Current Balance:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            '₱${eWalletBalance.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isSufficient
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Booking Total:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            '₱${booking.totalPrice.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: isSufficient
                                              ? Colors.green.shade100
                                              : Colors.red.shade100,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isSufficient
                                              ? '✓ Sufficient Balance'
                                              : '✗ Insufficient Balance',
                                          style: TextStyle(
                                            color: isSufficient
                                                ? Colors.green.shade800
                                                : Colors.red.shade800,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isSufficient) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: Colors.red.shade200),
                                    ),
                                    child: const Text(
                                      'Your E-Wallet balance is insufficient. Please top up your wallet or choose another payment method.',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Total Amount: ₱${booking.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final currentUser = _authService.getCurrentUser();
                    if (currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please log in to make payment'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    // Collect payment details based on method
                    Map<String, dynamic> paymentDetails = {};
                    if (selectedPaymentMethod == 'Credit Card') {
                      paymentDetails = {
                        'cardNumber': _cardNumberController.text,
                        'expiry': _expiryController.text,
                        'cvv': _cvvController.text,
                        'cardHolderName': _cardHolderController.text,
                      };
                    } else if (selectedPaymentMethod == 'GCash' ||
                        selectedPaymentMethod == 'PayMaya') {
                      paymentDetails = {
                        'mobileNumber': _gcashNumberController.text,
                        'referenceNumber': _referenceController.text,
                      };
                    } else if (selectedPaymentMethod == 'Bank Transfer') {
                      paymentDetails = {
                        'referenceNumber': _referenceController.text,
                      };
                    } else if (selectedPaymentMethod == 'Cash') {
                      paymentDetails = {
                        'referenceNumber': _referenceController.text,
                      };
                    }

                    try {
                      if (selectedPaymentMethod == 'Cash') {
                        // For cash payments, create payment record and update booking status to inProgress
                        final payment = await _paymentService.processPayment(
                          bookingId: booking.id,
                          userId: currentUser.uid,
                          guideId: booking.guideId ?? '',
                          amount: booking.totalPrice,
                          paymentMethod: PaymentMethod.cash,
                          paymentDetails: paymentDetails,
                        );

                        if (payment != null) {
                          await _db.updateBookingWithPayment(
                            booking.id,
                            paymentMethod: BookingPaymentMethod.cash,
                            paymentStatus: BookingPaymentStatus.pending,
                            status: BookingStatus.inProgress,
                          );

                          // Send notification to tourist about cash payment initiation
                          final touristNotification = _notificationService
                              .createCashPaymentInitiatedNotification(
                            userId: currentUser.uid,
                            amount: booking.totalPrice,
                            tourTitle: booking.tourTitle,
                          );
                          await _notificationService
                              .createNotification(touristNotification);

                          // Send notification to guide about cash payment pending
                          if (booking.guideId != null) {
                            final guideNotification = _notificationService
                                .createCashPaymentPendingForGuideNotification(
                              userId: booking.guideId!,
                              bookingId: booking.id,
                              touristName: currentUser.displayName ?? 'Tourist',
                              amount: booking.totalPrice,
                            );
                            await _notificationService
                                .createNotification(guideNotification);
                          }

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Cash payment selected. Booking is now in progress.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to process cash payment'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else if (selectedPaymentMethod == 'E-Wallet') {
                        // Handle E-Wallet payment
                        final user = await _db.getUser(currentUser.uid);
                        final eWalletBalance = user?.eWallet ?? 0.0;

                        if (eWalletBalance < booking.totalPrice) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Insufficient E-Wallet balance. Please top up to continue.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Fetch tour data to get inclusion prices
                        final tour = await _db.getTour(booking.tourId);
                        if (tour == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tour information not found'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Calculate guide amount (95% of Professional Guide's inclusion price)
                        double guideAmount = 0.0;
                        if (tour.inclusionPrices
                            .containsKey('Professional Guide')) {
                          guideAmount =
                              (tour.inclusionPrices['Professional Guide']! *
                                  0.95);
                        }

                        // Create payment record for eWallet payment
                        final payment = await _paymentService.processPayment(
                          bookingId: booking.id,
                          userId: currentUser.uid,
                          guideId: booking.guideId ?? '',
                          amount: booking.totalPrice,
                          paymentMethod: PaymentMethod.eWallet,
                          paymentDetails: paymentDetails,
                        );

                        if (payment != null) {
                          // Use transaction to deduct from tourist, add to guide, and update booking
                          await FirebaseFirestore.instance
                              .runTransaction((transaction) async {
                            // Get fresh tourist data
                            final touristDoc = await transaction.get(
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUser.uid));
                            final touristBalance =
                                (touristDoc.data()?['eWallet'] as num?)
                                        ?.toDouble() ??
                                    0.0;

                            if (touristBalance < booking.totalPrice) {
                              throw Exception('Insufficient balance');
                            }

                            // Get fresh guide data
                            final guideDoc = await transaction.get(
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(booking.guideId!));
                            final guideBalance =
                                (guideDoc.data()?['eWallet'] as num?)
                                        ?.toDouble() ??
                                    0.0;

                            // Deduct from tourist's eWallet
                            final newTouristBalance =
                                touristBalance - booking.totalPrice;
                            transaction.update(
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUser.uid),
                                {
                                  'eWallet': newTouristBalance,
                                });

                            // Add to guide's eWallet
                            final newGuideBalance = guideBalance + guideAmount;
                            transaction.update(
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(booking.guideId!),
                                {
                                  'eWallet': newGuideBalance,
                                });

                            // Update booking
                            transaction.update(
                                FirebaseFirestore.instance
                                    .collection('bookings')
                                    .doc(booking.id),
                                {
                                  'status': BookingStatus.paid.index,
                                  'paymentMethod':
                                      BookingPaymentMethod.eWallet.index,
                                  'paymentStatus':
                                      BookingPaymentStatus.paid.index,
                                  'paidAt': FieldValue.serverTimestamp(),
                                });
                          });

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Payment completed successfully using E-Wallet!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Failed to process eWallet payment'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else {
                        final payment = await _paymentService.processPayment(
                          bookingId: booking.id,
                          userId: currentUser.uid,
                          guideId: booking.guideId ?? '',
                          amount: booking.totalPrice,
                          paymentMethod: _mapStringToPaymentMethod(
                            selectedPaymentMethod,
                          ),
                          paymentDetails: paymentDetails,
                        );

                        if (payment != null) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Payment processed successfully via $selectedPaymentMethod',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Payment processing failed'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Payment failed: $e'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Pay Now'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
