import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Real data from Firestore
  Map<String, dynamic> _overviewData = {};
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoading = true;

  // Booking trends by tour data
  List<Map<String, dynamic>> _bookingTrendsByTour = [];
  bool _isLoadingBookingTrendsByTour = true;

  // Earnings data
  double _totalRevenue = 0.0;
  double _platformEarnings = 0.0;
  String _selectedPeriod = 'Monthly'; // Weekly, Monthly, Yearly
  bool _isLoadingEarnings = true;

  @override
  void initState() {
    super.initState();
    _loadOverviewData();
    _loadEarningsData();
  }

  Future<void> _loadOverviewData() async {
    setState(() {
      _isLoading = true;
      _isLoadingBookingTrendsByTour = true;
    });
    try {
      final data = await _fetchOverviewData();
      final activities = await _fetchRecentActivities();
      final bookingTrendsByTour = await _fetchBookingTrendsByTour();
      print('Overview data: $data');
      print('Activities: $activities');
      print('Setting booking trends data: $bookingTrendsByTour');
      setState(() {
        _overviewData = data;
        _recentActivities = activities;
        _bookingTrendsByTour = bookingTrendsByTour;
        _isLoading = false;
        _isLoadingBookingTrendsByTour = false;
      });
      print('Successfully set overview data');
    } catch (e) {
      print('Error in _loadOverviewData: $e');
      setState(() {
        _isLoading = false;
        _isLoadingBookingTrendsByTour = false;
      });
      // Handle error - could show snackbar
    }
  }

  Future<void> _loadEarningsData() async {
    setState(() {
      _isLoadingEarnings = true;
    });
    try {
      final earnings = await _fetchEarningsData(_selectedPeriod);
      setState(() {
        _totalRevenue = earnings['totalRevenue'] ?? 0.0;
        _platformEarnings = earnings['platformEarnings'] ?? 0.0;
        _isLoadingEarnings = false;
      });
    } catch (e) {
      print('Error loading earnings data: $e');
      setState(() {
        _isLoadingEarnings = false;
      });
    }
  }

  Future<Map<String, dynamic>> _fetchOverviewData() async {
    try {
      // Total Users: Count all documents in the users collection
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;

      // Total Bookings: Count all documents in the bookings collection
      final bookingsSnapshot = await _firestore.collection('bookings').get();
      final totalBookings = bookingsSnapshot.docs.length;

      // Active Tours: Count bookings with status pending(0), confirmed(1), paid(2), inProgress(3)
      final activeToursSnapshot = await _firestore
          .collection('bookings')
          .where('status', whereIn: [0, 1, 2, 3]).get();
      final activeTours = activeToursSnapshot.docs.length;

      // Monthly Revenue: Calculate the total sum of totalPrice for all documents in the bookings collection where status is 'completed' or 'paid', limited to the current month
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 1)
          .subtract(const Duration(days: 1));

      final monthlyRevenueSnapshot = await _firestore
          .collection('bookings')
          .where('status', whereIn: [2, 4]) // paid = 2, completed = 4
          .where('bookingDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('bookingDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      double monthlyRevenue = 0;
      for (var doc in monthlyRevenueSnapshot.docs) {
        final totalPrice = doc.data()['totalPrice'] ?? 0;
        monthlyRevenue += totalPrice.toDouble();
      }

      // Pending Verifications: Count guide_verifications with status pending (0)
      final pendingVerificationsSnapshot = await _firestore
          .collection('guide_verifications')
          .where('status', isEqualTo: 0) // VerificationStatus.pending = 0
          .get();
      final pendingVerifications = pendingVerificationsSnapshot.docs.length;

      // Average Rating: Compute the average by summing all rating values and dividing by the total number of bookings that contain a rating in the bookings collection
      final bookingsWithRatingsSnapshot = await _firestore
          .collection('bookings')
          .where('rating', isNotEqualTo: null)
          .get();

      double averageRating = 0;
      if (bookingsWithRatingsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (var doc in bookingsWithRatingsSnapshot.docs) {
          final rating = doc.data()['rating'];
          if (rating != null) {
            totalRating += rating.toDouble();
          }
        }
        averageRating = totalRating / bookingsWithRatingsSnapshot.docs.length;
      }

      return {
        'totalUsers': totalUsers,
        'totalBookings': totalBookings,
        'monthlyRevenue': monthlyRevenue,
        'activeTours': activeTours,
        'pendingVerifications': pendingVerifications,
        'averageRating': averageRating,
      };
    } catch (e) {
      print('Error fetching overview data: $e');
      // Return empty data on error
      return {
        'totalUsers': 0,
        'totalBookings': 0,
        'monthlyRevenue': 0.0,
        'activeTours': 0,
        'pendingVerifications': 0,
        'averageRating': 0.0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> _fetchBookingTrendsByTour() async {
    // Fetch all bookings
    final bookingsSnapshot = await _firestore.collection('bookings').get();

    // Group bookings by tourId
    final Map<String, Map<String, dynamic>> tourBookings = {};

    for (var doc in bookingsSnapshot.docs) {
      final data = doc.data();
      final tourId = data['tourId'] as String?;
      final tourTitle = data['tourTitle'] as String?;

      if (tourId != null &&
          tourId.isNotEmpty &&
          tourTitle != null &&
          tourTitle.isNotEmpty) {
        if (tourBookings.containsKey(tourId)) {
          tourBookings[tourId]!['count'] =
              (tourBookings[tourId]!['count'] ?? 0) + 1;
        } else {
          tourBookings[tourId] = {
            'tourId': tourId,
            'tourTitle': tourTitle,
            'count': 1,
          };
        }
      }
    }

    // Convert to list and sort by count descending
    final result = tourBookings.values.toList();
    result.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    return result;
  }

  Future<Map<String, dynamic>> _fetchEarningsData(String period) async {
    try {
      final now = DateTime.now();
      DateTime startDate;

      // Calculate date range based on period
      switch (period) {
        case 'Weekly':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'Monthly':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'Yearly':
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, 1);
      }

      // Query bookings with status paid (2) or completed (4) within the date range
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('status', whereIn: [2, 4]) // paid = 2, completed = 4
          .where('bookingDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();

      double totalRevenue = 0.0;

      // For each booking, fetch the tour to get inclusionPrices.professionalGuide
      for (var bookingDoc in bookingsSnapshot.docs) {
        final bookingData = bookingDoc.data();
        final tourId = bookingData['tourId'] as String?;

        if (tourId != null && tourId.isNotEmpty) {
          try {
            final tourDoc =
                await _firestore.collection('tours').doc(tourId).get();
            if (tourDoc.exists) {
              final tourData = tourDoc.data();
              final inclusionPrices =
                  tourData?['inclusionPrices'] as Map<String, dynamic>?;

              if (inclusionPrices != null &&
                  inclusionPrices.containsKey('Professional Guide')) {
                final professionalGuideFee =
                    inclusionPrices['Professional Guide'];
                if (professionalGuideFee != null) {
                  final fee = (professionalGuideFee is double)
                      ? professionalGuideFee
                      : (professionalGuideFee is int)
                          ? professionalGuideFee.toDouble()
                          : double.tryParse(professionalGuideFee.toString()) ??
                              0.0;
                  totalRevenue += fee;
                }
              }
            }
          } catch (e) {
            print('Error fetching tour data for booking ${bookingDoc.id}: $e');
            // Continue with next booking
          }
        }
      }

      // Calculate platform earnings (5% of total revenue)
      final platformEarnings = totalRevenue * 0.05;

      return {
        'totalRevenue': totalRevenue,
        'platformEarnings': platformEarnings,
      };
    } catch (e) {
      print('Error fetching earnings data: $e');
      return {
        'totalRevenue': 0.0,
        'platformEarnings': 0.0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecentActivities() async {
    List<Map<String, dynamic>> activities = [];

    try {
      // Fetch recent user registrations
      final usersSnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();
        final displayName =
            userData['displayName'] ?? userData['email'] ?? 'Unknown User';
        final role = userData['role'] ?? 'tourist';
        final capitalizedRole =
            role.isNotEmpty ? role[0].toUpperCase() + role.substring(1) : role;

        activities.add({
          'title': 'New user registration',
          'subtitle': '$displayName registered as a $capitalizedRole',
          'timestamp': userData['createdAt'] as Timestamp?,
          'icon': Icons.person_add,
        });
      }

      // Fetch recent bookings
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .orderBy('bookingDate', descending: true)
          .limit(5)
          .get();

      for (var doc in bookingsSnapshot.docs) {
        final bookingData = doc.data();
        final tourTitle = bookingData['tourTitle'] ??
            'Tour ${bookingData['tourId'] ?? 'Unknown'}';

        activities.add({
          'title': 'Tour booked',
          'subtitle': '$tourTitle was booked',
          'timestamp': bookingData['bookingDate'] as Timestamp?,
          'icon': Icons.book_online,
        });
      }

      // Fetch recent payments
      final paymentsSnapshot = await _firestore
          .collection('payments')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (var doc in paymentsSnapshot.docs) {
        final paymentData = doc.data();
        final amount = paymentData['amount'] ?? 0;
        final bookingId = paymentData['bookingId'] ?? 'Unknown';

        activities.add({
          'title': 'Payment processed',
          'subtitle':
              'Booking #$bookingId payment of ₱${amount.toStringAsFixed(2)} completed',
          'timestamp': paymentData['createdAt'] as Timestamp?,
          'icon': Icons.payment,
        });
      }

      // Sort all activities by timestamp (most recent first)
      activities.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      // Return only the 10 most recent activities
      return activities.take(10).toList();
    } catch (e) {
      print('Error fetching recent activities: $e');
      return [];
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Dashboard Overview',
            style: AppTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Monitor your platform\'s performance and key metrics',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 32),

          // KPI Cards - First Row
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Total Users',
                  (_overviewData['totalUsers'] ?? 0).toString(),
                  Icons.people,
                  AppTheme.primaryColor,
                  '+12% from last month',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildKPICard(
                  'Active Tours',
                  (_overviewData['activeTours'] ?? 0).toString(),
                  Icons.tour,
                  AppTheme.successColor,
                  '+8% from last month',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildKPICard(
                  'Total Bookings',
                  (_overviewData['totalBookings'] ?? 0).toString(),
                  Icons.book_online,
                  AppTheme.accentColor,
                  '+15% from last month',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // KPI Cards - Second Row
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Pending Verifications',
                  (_overviewData['pendingVerifications'] ?? 0).toString(),
                  Icons.verified_user,
                  AppTheme.primaryColor,
                  'Requires attention',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildKPICard(
                  'Average Rating',
                  (_overviewData['averageRating'] ?? 0).toStringAsFixed(1),
                  Icons.star,
                  AppTheme.successColor,
                  'Platform rating',
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),

          // Earnings Statistics Section
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Earnings Statistics',
                        style: AppTheme.headlineSmall,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedPeriod,
                          items: ['Weekly', 'Monthly', 'Yearly']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: AppTheme.bodyMedium),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedPeriod = newValue;
                              });
                              _loadEarningsData();
                            }
                          },
                          underline: const SizedBox(),
                          icon: Icon(Icons.arrow_drop_down,
                              color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _isLoadingEarnings
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          children: [
                            Expanded(
                              child: _buildEarningsCard(
                                'Total Revenue',
                                '₱${_totalRevenue.toStringAsFixed(2)}',
                                Icons.attach_money,
                                AppTheme.successColor,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildEarningsCard(
                                'Platform Earnings (5%)',
                                '₱${_platformEarnings.toStringAsFixed(2)}',
                                Icons.account_balance_wallet,
                                AppTheme.accentColor,
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),

          // Charts Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bookings Trend Chart
              Expanded(
                flex: 2,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking Trends',
                          style: AppTheme.headlineSmall,
                        ),
                        const SizedBox(height: 24),
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
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
          const SizedBox(height: 48),

          // Recent Activity
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: AppTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  if (_recentActivities.isEmpty)
                    const Center(
                      child: Text('No recent activity'),
                    )
                  else
                    ..._recentActivities.map((activity) {
                      final timestamp = activity['timestamp'] as Timestamp?;
                      final timeAgo = timestamp != null
                          ? _formatTimeAgo(timestamp.toDate())
                          : 'Unknown time';

                      return _buildActivityItem(
                        activity['title'] as String,
                        activity['subtitle'] as String,
                        timeAgo,
                        activity['icon'] as IconData,
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 32, color: color),
                const Spacer(),
                Icon(Icons.trending_up, size: 20, color: AppTheme.successColor),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: AppTheme.headlineLarge.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: color),
                const Spacer(),
                Icon(Icons.trending_up, size: 18, color: AppTheme.successColor),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTheme.headlineMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
      String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall
                      .copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: color),
        ],
      ),
    );
  }

  Widget _buildBookingTrendsBarChart() {
    print(
        '_buildBookingTrendsBarChart called with data: $_bookingTrendsByTour');
    if (_bookingTrendsByTour.isEmpty) {
      print(
          '_buildBookingTrendsBarChart: Data is empty, showing no data message');
      return const Center(
        child: Text('No booking data available'),
      );
    }
    print('_buildBookingTrendsBarChart: Data is not empty, building chart');

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

  Widget _buildActivityItem(
      String title, String subtitle, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
