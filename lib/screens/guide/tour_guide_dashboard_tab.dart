import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/booking_model.dart';
import '../../models/payment_model.dart';
import '../../models/review_model.dart';
import '../../models/tour_model.dart';
import '../../models/user_model.dart';
import '../../widgets/auto_translated_text.dart';
import 'create_tour_screen.dart';
import 'bookings_management_screen.dart';
import 'guide_submit_credentials_screen.dart';

// Activity item data class
class ActivityItem {
  final String title;
  final String time;
  final Widget iconWidget;
  final DateTime timestamp;

  ActivityItem({
    required this.title,
    required this.time,
    required this.iconWidget,
    required this.timestamp,
  });
}

class TourGuideDashboardTab extends StatefulWidget {
  const TourGuideDashboardTab({super.key});

  @override
  State<TourGuideDashboardTab> createState() => _TourGuideDashboardTabState();
}

class _TourGuideDashboardTabState extends State<TourGuideDashboardTab> {
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();

  bool _isLoading = true;
  String? _error;
  String? _userName;
  List<ActivityItem> _recentActivities = [];
  UserModel? _currentUser;

  // Overview stats
  int _activeTours = 0;
  double _earnings = 0.0;
  double _rating = 0.0;
  int _requests = 0;

  // Booking trends by tour data
  List<Map<String, dynamic>> _bookingTrendsByTour = [];
  bool _isLoadingBookingTrendsByTour = true;

  UserStatus? _userStatus;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isLoadingBookingTrendsByTour = true;
    });

    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
          _isLoadingBookingTrendsByTour = false;
        });
        return;
      }

      print('Loading dashboard data for guide: ${currentUser.uid}');

      // Load user profile to get display name
      final userProfile = await _db.getUser(currentUser.uid);
      final userName = userProfile?.displayName ?? 'Guide';
      final userStatus = userProfile?.status;
      _currentUser = userProfile;

      // Load overview stats
      await _loadOverviewStats(currentUser.uid);

      // Load recent activities
      await _loadRecentActivities(currentUser.uid);

      // Load booking trends by tour
      await _loadBookingTrendsByTour(currentUser.uid);

      setState(() {
        _userName = userName;
        _userStatus = userStatus;
        _isLoading = false;
        _isLoadingBookingTrendsByTour = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _error =
            'Failed to load dashboard data. Please check your connection and try again.';
        _isLoading = false;
        _isLoadingBookingTrendsByTour = false;
      });
    }
  }

  Future<void> _loadOverviewStats(String guideId) async {
    // Load bookings assigned to the guide
    final bookings = await _db.getBookingsByGuide(guideId);

    // Active Tours: total number of bookings with status pending, confirmed, paid, or inProgress
    final activeTours = bookings
        .where((booking) => [
              BookingStatus.pending,
              BookingStatus.confirmed,
              BookingStatus.paid,
              BookingStatus.inProgress
            ].contains(booking.status))
        .length;

    // Earnings: calculate guide's share (95%) from tour inclusionPrices for paid/completed bookings
    double earnings = 0.0;
    final relevantBookings = bookings.where((booking) =>
        booking.status == BookingStatus.paid ||
        booking.status == BookingStatus.completed);

    for (final booking in relevantBookings) {
      final tour = await _db.getTour(booking.tourId);
      if (tour != null && tour.inclusionPrices.isNotEmpty) {
        final totalInclusionPrices = tour.inclusionPrices.values
            .fold<double>(0.0, (sum, price) => sum + price);
        final guideShare = totalInclusionPrices * 0.95; // Deduct 5%
        earnings += guideShare;
      }
    }

    // Rating: average rating from bookings that contain a rating value
    final ratedBookings = bookings.where((booking) => booking.rating != null);
    final rating = ratedBookings.isNotEmpty
        ? ratedBookings
                .map((booking) => booking.rating!)
                .reduce((a, b) => a + b) /
            ratedBookings.length
        : 0.0;

    // Requests: total number of bookings with status pending
    final requests = bookings
        .where((booking) => booking.status == BookingStatus.pending)
        .length;

    setState(() {
      _activeTours = activeTours;
      _earnings = earnings;
      _rating = rating;
      _requests = requests;
    });
  }

  Future<void> _loadRecentActivities(String guideId) async {
    // Fetch recent data
    final bookings = await _db.getBookingsByGuide(guideId);
    // print('Found ${bookings.length} bookings');

    final payments = await _db.getPaymentsByGuide(guideId);
    // print('Found ${payments.length} payments');

    final reviews = await _db.getRecentGuideReviews(guideId);
    // print('Found ${reviews.length} reviews');

    // Combine and sort activities
    final activities = <ActivityItem>[];

    // Add booking activities
    for (final booking in bookings) {
      if (booking.status == BookingStatus.pending) {
        activities.add(ActivityItem(
          title: 'New booking request for ${booking.tourTitle}',
          time: _formatTimeAgo(booking.bookingDate),
          iconWidget: Icon(Icons.calendar_today,
              color: AppTheme.primaryColor, size: 20),
          timestamp: booking.bookingDate,
        ));
      } else if (booking.status == BookingStatus.completed) {
        activities.add(ActivityItem(
          title: 'Tour completed: ${booking.tourTitle}',
          time: _formatTimeAgo(booking.completedAt ?? booking.bookingDate),
          iconWidget:
              Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
          timestamp: booking.completedAt ?? booking.bookingDate,
        ));
      }
    }

    // Add payment activities
    for (final payment in payments) {
      if (payment.status == PaymentStatus.completed) {
        activities.add(ActivityItem(
          title: 'Payment received for tour',
          time: _formatTimeAgo(payment.completedAt ?? payment.createdAt),
          iconWidget: Text('₱',
              style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          timestamp: payment.completedAt ?? payment.createdAt,
        ));
      }
    }

    // Add review activities
    for (final review in reviews) {
      activities.add(ActivityItem(
        title: 'New ${review.overallRating.round()}-star review received',
        time: _formatTimeAgo(review.createdAt),
        iconWidget: Icon(Icons.star, color: AppTheme.primaryColor, size: 20),
        timestamp: review.createdAt,
      ));
    }

    // Sort by timestamp (most recent first) and take top 10
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recentActivities = activities.take(10).toList();

    setState(() {
      _recentActivities = recentActivities;
    });
  }

  Future<void> _loadBookingTrendsByTour(String guideId) async {
    try {
      // Fetch bookings for this guide
      final bookings = await _db.getBookingsByGuide(guideId);

      // Group bookings by tour title
      final Map<String, Map<String, dynamic>> tourBookings = {};

      for (final booking in bookings) {
        final tourTitle = booking.tourTitle;
        if (tourTitle.isNotEmpty) {
          if (tourBookings.containsKey(tourTitle)) {
            tourBookings[tourTitle]!['count'] =
                (tourBookings[tourTitle]!['count'] ?? 0) + 1;
          } else {
            tourBookings[tourTitle] = {
              'tourTitle': tourTitle,
              'count': 1,
            };
          }
        }
      }

      // Convert to list and sort by count descending
      final result = tourBookings.values.toList();
      result.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      setState(() {
        _bookingTrendsByTour = result;
      });
    } catch (e) {
      print('Error loading booking trends by tour: $e');
      setState(() {
        _bookingTrendsByTour = [];
      });
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  void _showTopUpDialog(BuildContext context) {
    final TextEditingController _amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const AutoTranslatedText(
            'Top Up E-Wallet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AutoTranslatedText(
                'Enter the amount to add to your E-Wallet:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (₱)',
                  border: OutlineInputBorder(),
                  prefixText: '₱',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const AutoTranslatedText('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amountText = _amountController.text.trim();
                final amount = double.tryParse(amountText);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: AutoTranslatedText(
                          'Please enter a valid amount greater than 0'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null && _currentUser != null) {
                    final newBalance = (_currentUser!.eWallet ?? 0.0) + amount;
                    await DatabaseService()
                        .updateEWalletBalance(user.uid, newBalance);

                    // Update local state immediately
                    setState(() {
                      _currentUser = UserModel(
                        uid: _currentUser!.uid,
                        email: _currentUser!.email,
                        role: _currentUser!.role,
                        displayName: _currentUser!.displayName,
                        phoneNumber: _currentUser!.phoneNumber,
                        languages: _currentUser!.languages,
                        toursCompleted: _currentUser!.toursCompleted,
                        averageRating: _currentUser!.averageRating,
                        photoURL: _currentUser!.photoURL,
                        createdAt: _currentUser!.createdAt,
                        activeStatus: _currentUser!.activeStatus,
                        favoriteDestination: _currentUser!.favoriteDestination,
                        specializations: _currentUser!.specializations,
                        status: _currentUser!.status,
                        isActive: _currentUser!.isActive,
                        isLGUVerified: _currentUser!.isLGUVerified,
                        category: _currentUser!.category,
                        certifications: _currentUser!.certifications,
                        lguDocuments: _currentUser!.lguDocuments,
                        availability: _currentUser!.availability,
                        eWallet: newBalance,
                      );
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: AutoTranslatedText(
                            'Successfully topped up ₱${amount.toStringAsFixed(2)}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: AutoTranslatedText(
                          'Failed to top up. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonHighlight,
              ),
              child: const AutoTranslatedText('Top Up'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $_userName!',
                  style: AppTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ready to guide tourists today?',
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_userStatus == UserStatus.pending ||
              _userStatus == UserStatus.rejected) ...[
            // Verification Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.accentColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user,
                    color: AppTheme.accentColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verification Required',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Submit your credentials to become a verified tour guide',
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const GuideSubmitCredentialsScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Submit Now'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // E-Wallet Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AutoTranslatedText(
                        'E-Wallet',
                        style: AppTheme.headlineSmall,
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showTopUpDialog(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: const AutoTranslatedText('Top Up'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.buttonHighlight,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      AutoTranslatedText(
                        'Balance: ₱${_currentUser?.eWallet?.toStringAsFixed(2) ?? '0.00'}',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Stats Overview
          Text('Overview', style: AppTheme.headlineSmall),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Active Tours',
                  _activeTours.toString(),
                  Icon(Icons.tour, color: AppTheme.primaryColor, size: 32),
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Earnings',
                  '₱${_earnings.toStringAsFixed(0)}',
                  Text('₱',
                      style: TextStyle(
                          color: AppTheme.successColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                  AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Rating',
                  _rating.toStringAsFixed(1),
                  Icon(Icons.star, color: Colors.amber, size: 32),
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Requests',
                  _requests.toString(),
                  Icon(Icons.notifications,
                      color: AppTheme.accentColor, size: 32),
                  AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Booking Trends
          Text('Booking Trends', style: AppTheme.headlineSmall),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isLoadingBookingTrendsByTour
                ? const Center(child: CircularProgressIndicator())
                : _buildBookingTrendsBarChart(),
          ),
          const SizedBox(height: 24),

          // Recent Activity
          Text('Recent Activity', style: AppTheme.headlineSmall),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  Text(_error!, style: AppTheme.bodyMedium),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadDashboardData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_recentActivities.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.history, color: AppTheme.textSecondary, size: 48),
                  const SizedBox(height: 8),
                  Text('No recent activity', style: AppTheme.bodyMedium),
                ],
              ),
            )
          else
            ..._recentActivities.map((activity) => _buildActivityItem(
                  activity.title,
                  activity.time,
                  activity.iconWidget,
                )),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Widget iconWidget, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          iconWidget,
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.headlineSmall.copyWith(color: color),
          ),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, Widget iconWidget) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: iconWidget,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(time,
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBookingTrends() {
    final trends = [
      {'name': 'Kawasan Falls Canyoonering', 'rating': '4.9'},
      {'name': 'Oslob Whale Shark Encounter', 'rating': '4.8'},
      {'name': 'Sumilon Island Snorkeling', 'rating': '4.7'},
      {'name': 'Chocolate Hills Adventure', 'rating': '4.6'},
      {'name': 'Bohol Countryside Tour', 'rating': '4.5'},
    ];

    return trends
        .map(
            (trend) => _buildBookingTrendItem(trend['name']!, trend['rating']!))
        .toList();
  }

  Widget _buildBookingTrendItem(String tourName, String rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Expanded(
            child: Text(tourName, style: AppTheme.bodyMedium),
          ),
          Icon(Icons.star, color: Colors.amber, size: 16),
          const SizedBox(width: 4),
          Text(rating,
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBookingTrendsBarChart() {
    if (_bookingTrendsByTour.isEmpty) {
      return const Center(
        child: Text('No booking data available'),
      );
    }

    // Take top 10 tours or all if less than 10
    final displayData = _bookingTrendsByTour.take(10).toList();
    final maxCount = displayData.isNotEmpty
        ? displayData
            .map((e) => e['count'] as int)
            .reduce((a, b) => a > b ? a : b)
        : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bookings by Tour',
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: displayData.map((tourData) {
              final count = tourData['count'] as int;
              final tourTitle = tourData['tourTitle'] as String;
              final height = (count / maxCount) * 120.0; // Max height of 120

              return Column(
                children: [
                  Expanded(
                    child: Container(
                      width: 40,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 30,
                        height: height,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 60,
                    child: Text(
                      tourTitle,
                      style: AppTheme.bodySmall.copyWith(fontSize: 10),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    count.toString(),
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Most Booked', style: AppTheme.bodySmall),
            Text('Least Booked', style: AppTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
