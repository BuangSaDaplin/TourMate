import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  String _selectedTimeRange = '7d'; // 7d, 30d, 90d, 1y
  String _selectedMetric = 'bookings'; // bookings, revenue, users, ratings

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Real data from Firestore
  Map<String, dynamic> _analyticsData = {};
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoadingAnalytics = true;

  // Real time series data from Firestore
  List<Map<String, dynamic>> _bookingTrends = [];
  List<Map<String, dynamic>> _ratingTrends = [];
  bool _isLoadingTrends = true;

  // Booking trends by tour data
  List<Map<String, dynamic>> _bookingTrendsByTour = [];
  bool _isLoadingBookingTrendsByTour = true;

  Map<String, int> _categoryDistribution = {};
  Map<String, int> _userTypeDistribution = {};

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoadingAnalytics = true;
      _isLoadingTrends = true;
      _isLoadingBookingTrendsByTour = true;
    });
    try {
      print('_loadAnalyticsData: Starting data fetch');
      final data = await _fetchAnalyticsData();
      print('_loadAnalyticsData: Analytics data fetched: $data');
      final bookingTrends = await _fetchBookingTrends();
      print('_loadAnalyticsData: Booking trends fetched: $bookingTrends');
      final ratingTrends = await _fetchRatingTrends();
      print('_loadAnalyticsData: Rating trends fetched: $ratingTrends');
      final bookingTrendsByTour = await _fetchBookingTrendsByTour();
      print(
          '_loadAnalyticsData: Booking trends by tour fetched: $bookingTrendsByTour');
      final recentActivities = await _fetchRecentActivities();
      print('_loadAnalyticsData: Recent activities fetched: $recentActivities');

      // Temporarily comment out problematic fetches
      // final categoryDistribution = await _fetchCategoryDistribution();
      // print('_loadAnalyticsData: Category distribution fetched: $categoryDistribution');
      // final userTypeDistribution = await _fetchUserTypeDistribution();
      // print('_loadAnalyticsData: User type distribution fetched: $userTypeDistribution');

      print('Setting booking trends data: $bookingTrendsByTour');
      setState(() {
        _analyticsData = data;
        _bookingTrends = bookingTrends;
        _ratingTrends = ratingTrends;
        _bookingTrendsByTour = bookingTrendsByTour;
        _recentActivities = recentActivities;
        // _categoryDistribution = categoryDistribution;
        // _userTypeDistribution = userTypeDistribution;
        _isLoadingAnalytics = false;
        _isLoadingTrends = false;
        _isLoadingBookingTrendsByTour = false;
      });
      print('After setState, _bookingTrendsByTour: $_bookingTrendsByTour');
    } catch (e) {
      print('_loadAnalyticsData: Error occurred: $e');
      setState(() {
        _isLoadingAnalytics = false;
        _isLoadingTrends = false;
        _isLoadingBookingTrendsByTour = false;
      });
      // Handle error - could show snackbar
    }
  }

  Future<Map<String, dynamic>> _fetchAnalyticsData() async {
    // Fetch total users
    final usersSnapshot = await _firestore.collection('users').get();
    final totalUsers = usersSnapshot.docs.length;

    // Fetch total bookings
    final bookingsSnapshot = await _firestore.collection('bookings').get();
    final totalBookings = bookingsSnapshot.docs.length;

    // Calculate total revenue from bookings where status is paid (2) or completed (4)
    double totalRevenue = 0;
    for (var doc in bookingsSnapshot.docs) {
      final data = doc.data();
      final status = data['status'] ?? 0;
      if (status == 2 || status == 4) {
        // paid or completed
        final totalPrice = data['totalPrice'] ?? 0;
        totalRevenue += totalPrice.toDouble();
      }
    }

    // Fetch active tours
    final toursSnapshot = await _firestore
        .collection('tours')
        .where('status', isEqualTo: 'published')
        .get();
    final activeTours = toursSnapshot.docs.length;

    // Calculate average rating from reviews
    final reviewsSnapshot = await _firestore.collection('reviews').get();
    double avgRating = 0;
    if (reviewsSnapshot.docs.isNotEmpty) {
      double totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        totalRating += (doc.data()['rating'] ?? 0).toDouble();
      }
      avgRating = totalRating / reviewsSnapshot.docs.length;
    }

    // For growth calculations, we'd need historical data
    // For now, return 0 as placeholder
    return {
      'totalBookings': totalBookings,
      'totalRevenue': totalRevenue,
      'totalUsers': totalUsers,
      'activeTours': activeTours,
      'avgRating': avgRating,
      'bookingGrowth': 0.0, // Would need historical data
      'revenueGrowth': 0.0, // Would need historical data
      'userGrowth': 0.0, // Would need historical data
    };
  }

  Future<List<Map<String, dynamic>>> _fetchBookingTrends() async {
    // Get bookings from the last 7 days
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final bookingsSnapshot = await _firestore
        .collection('bookings')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
        .orderBy('createdAt', descending: false)
        .get();

    // Group bookings by date
    final Map<String, Map<String, dynamic>> dailyData = {};

    for (var doc in bookingsSnapshot.docs) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        final dateKey =
            '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
        final amount = (data['totalPrice'] ?? 0).toDouble();

        if (dailyData.containsKey(dateKey)) {
          dailyData[dateKey]!['bookings'] =
              (dailyData[dateKey]!['bookings'] ?? 0) + 1;
          dailyData[dateKey]!['revenue'] =
              (dailyData[dateKey]!['revenue'] ?? 0) + amount;
        } else {
          dailyData[dateKey] = {
            'date': dateKey,
            'bookings': 1,
            'revenue': amount,
          };
        }
      }
    }

    // Convert to list and sort by date
    final result = dailyData.values.toList();
    result.sort((a, b) => a['date'].compareTo(b['date']));

    return result;
  }

  Future<List<Map<String, dynamic>>> _fetchRatingTrends() async {
    // Get reviews from the last 7 days
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final reviewsSnapshot = await _firestore
        .collection('reviews')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
        .orderBy('createdAt', descending: false)
        .get();

    // Group reviews by date
    final Map<String, Map<String, dynamic>> dailyData = {};

    for (var doc in reviewsSnapshot.docs) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        final dateKey =
            '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
        final rating = (data['rating'] ?? 0).toDouble();

        if (dailyData.containsKey(dateKey)) {
          dailyData[dateKey]!['totalRating'] =
              (dailyData[dateKey]!['totalRating'] ?? 0) + rating;
          dailyData[dateKey]!['totalReviews'] =
              (dailyData[dateKey]!['totalReviews'] ?? 0) + 1;
        } else {
          dailyData[dateKey] = {
            'date': dateKey,
            'totalRating': rating,
            'totalReviews': 1,
          };
        }
      }
    }

    // Calculate average rating and convert to list
    final result = dailyData.values.map((data) {
      final avgRating = data['totalReviews'] > 0
          ? data['totalRating'] / data['totalReviews']
          : 0.0;
      return {
        'date': data['date'],
        'avgRating': avgRating,
        'totalReviews': data['totalReviews'],
      };
    }).toList();

    result.sort((a, b) => a['date'].compareTo(b['date']));

    return result;
  }

  Future<Map<String, int>> _fetchCategoryDistribution() async {
    final toursSnapshot = await _firestore.collection('tours').get();
    final Map<String, int> categoryCount = {};

    for (var doc in toursSnapshot.docs) {
      final data = doc.data();
      final category = data['category'] ?? 'Other';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }

    return categoryCount;
  }

  Future<Map<String, int>> _fetchUserTypeDistribution() async {
    final usersSnapshot = await _firestore.collection('users').get();
    final Map<String, int> userTypeCount = {
      'Tourists': 0,
      'Tour Guides': 0,
      'Admins': 0,
    };

    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      final role = data['role'] ?? 'tourist';

      switch (role) {
        case 'tourist':
          userTypeCount['Tourists'] = userTypeCount['Tourists']! + 1;
          break;
        case 'guide':
          userTypeCount['Tour Guides'] = userTypeCount['Tour Guides']! + 1;
          break;
        case 'admin':
          userTypeCount['Admins'] = userTypeCount['Admins']! + 1;
          break;
      }
    }

    return userTypeCount;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SUCCESS DASHBOARD - Stat Cards
            Text(
              'Platform Performance',
              style: AppTheme.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Real-time analytics overview',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Stat Cards
            _isLoadingAnalytics
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                            'Users',
                            _analyticsData['totalUsers']?.toString() ?? '0',
                            Icons.people,
                            Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                            'Bookings',
                            _analyticsData['totalBookings']?.toString() ?? '0',
                            Icons.book_online,
                            Colors.green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                            'Revenue',
                            '₱${(_analyticsData['totalRevenue'] as double?)?.toStringAsFixed(0) ?? '0'}',
                            Icons.attach_money,
                            Colors.orange),
                      ),
                    ],
                  ),

            const SizedBox(height: 24),

            // Chart: Booking Trends
            Text(
              'Booking Trends',
              style: AppTheme.headlineSmall,
            ),
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
            Text(
              'Recent Activity',
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

            const SizedBox(height: 24),

            // Success Message
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '🎉 Platform is running successfully! All systems operational.',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
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
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockBarChart() {
    // Simple bar chart using Row of colored Containers showing upward trend
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Bookings Trend',
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              // Upward trend: 30, 40, 45, 55, 65, 75, 90
              final heights = [30.0, 40.0, 45.0, 55.0, 65.0, 75.0, 90.0];
              final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

              return Column(
                children: [
                  Expanded(
                    child: Container(
                      width: 30,
                      height: heights[index],
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(days[index], style: AppTheme.bodySmall),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('30', style: AppTheme.bodySmall),
            Text('90', style: AppTheme.bodySmall),
          ],
        ),
      ],
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

  Widget _buildKPICards() {
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            'Total Bookings',
            _analyticsData['totalBookings'].toString(),
            Icons.book_online,
            Colors.blue,
            '${_analyticsData['bookingGrowth'] > 0 ? '+' : ''}${_analyticsData['bookingGrowth']}%',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKPICard(
            'Revenue',
            '\$${_analyticsData['totalRevenue'].toStringAsFixed(0)}',
            Icons.attach_money,
            Colors.green,
            '${_analyticsData['revenueGrowth'] > 0 ? '+' : ''}${_analyticsData['revenueGrowth']}%',
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(
      String title, String value, IconData icon, Color color, String change) {
    final isPositive = !change.startsWith('-');

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                change,
                style: AppTheme.bodySmall.copyWith(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainChart() {
    switch (_selectedMetric) {
      case 'bookings':
        return _buildLineChart(
          _bookingTrends
              .map((data) => FlSpot(
                    _bookingTrends.indexOf(data).toDouble(),
                    data['bookings'].toDouble(),
                  ))
              .toList(),
          'Daily Bookings',
          Colors.blue,
        );
      case 'revenue':
        return _buildLineChart(
          _bookingTrends
              .map((data) => FlSpot(
                    _bookingTrends.indexOf(data).toDouble(),
                    data['revenue'],
                  ))
              .toList(),
          'Daily Revenue (\$)',
          Colors.green,
        );
      case 'ratings':
        return _buildLineChart(
          _ratingTrends
              .map((data) => FlSpot(
                    _ratingTrends.indexOf(data).toDouble(),
                    data['avgRating'],
                  ))
              .toList(),
          'Average Rating',
          Colors.orange,
        );
      default:
        return _buildLineChart(
          _bookingTrends
              .map((data) => FlSpot(
                    _bookingTrends.indexOf(data).toDouble(),
                    data['bookings'].toDouble(),
                  ))
              .toList(),
          'Daily Bookings',
          Colors.blue,
        );
    }
  }

  Widget _buildLineChart(List<FlSpot> spots, String title, Color color) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: AppTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _bookingTrends.length) {
                  final date = _bookingTrends[index]['date'].toString();
                  return Text(
                    date.substring(8, 10), // Show day only
                    style: AppTheme.bodySmall,
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(
      String title, Map<String, int> data, List<Color> colors) {
    final total = data.values.reduce((a, b) => a + b);
    int colorIndex = 0;

    return Container(
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
      child: Column(
        children: [
          Text(title,
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sections: data.entries.map((entry) {
                  final percentage = (entry.value / total * 100).round();
                  final color = colors[colorIndex % colors.length];
                  colorIndex++;

                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    title: '$percentage%',
                    color: color,
                    radius: 50,
                    titleStyle: AppTheme.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...data.entries.map((entry) {
            final color =
                colors[(data.keys.toList().indexOf(entry.key)) % colors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: AppTheme.bodySmall,
                    ),
                  ),
                  Text(
                    entry.value.toString(),
                    style: AppTheme.bodySmall
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInsightsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                'Top Performing Category',
                'Adventure Tours',
                '+25% bookings this month',
                Icons.trending_up,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightCard(
                'Peak Booking Hours',
                '2:00 PM - 6:00 PM',
                'Most popular booking time',
                Icons.schedule,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                'User Retention Rate',
                '78%',
                '+5% from last month',
                Icons.people,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightCard(
                'Average Session Time',
                '12 min',
                'User engagement metric',
                Icons.timer,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightCard(
      String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTheme.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeRangeLabel(String range) {
    switch (range) {
      case '7d':
        return '7 Days';
      case '30d':
        return '30 Days';
      case '90d':
        return '90 Days';
      case '1y':
        return '1 Year';
      default:
        return '7 Days';
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
