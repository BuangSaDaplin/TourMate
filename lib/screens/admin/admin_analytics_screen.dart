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
  bool _isLoadingAnalytics = true;

  // Real time series data from Firestore
  List<Map<String, dynamic>> _bookingTrends = [];
  List<Map<String, dynamic>> _ratingTrends = [];
  bool _isLoadingTrends = true;

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
    });
    try {
      final data = await _fetchAnalyticsData();
      final bookingTrends = await _fetchBookingTrends();
      final ratingTrends = await _fetchRatingTrends();
      final categoryDistribution = await _fetchCategoryDistribution();
      final userTypeDistribution = await _fetchUserTypeDistribution();

      setState(() {
        _analyticsData = data;
        _bookingTrends = bookingTrends;
        _ratingTrends = ratingTrends;
        _categoryDistribution = categoryDistribution;
        _userTypeDistribution = userTypeDistribution;
        _isLoadingAnalytics = false;
        _isLoadingTrends = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAnalytics = false;
        _isLoadingTrends = false;
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

    // Calculate total revenue from payments
    final paymentsSnapshot = await _firestore
        .collection('payments')
        .where('status', isEqualTo: 'completed')
        .get();
    double totalRevenue = 0;
    for (var doc in paymentsSnapshot.docs) {
      final amount = doc.data()['amount'] ?? 0;
      totalRevenue += amount.toDouble();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedTimeRange = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7d', child: Text('Last 7 Days')),
              const PopupMenuItem(value: '30d', child: Text('Last 30 Days')),
              const PopupMenuItem(value: '90d', child: Text('Last 90 Days')),
              const PopupMenuItem(value: '1y', child: Text('Last Year')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(
                    _getTimeRangeLabel(_selectedTimeRange),
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down,
                      color: AppTheme.primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Cards
            _buildKPICards(),

            const SizedBox(height: 24),

            // Charts Section
            Text(
              'Performance Trends',
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Metric Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: DropdownButton<String>(
                value: _selectedMetric,
                isExpanded: true,
                underline: Container(),
                items: [
                  DropdownMenuItem(
                    value: 'bookings',
                    child: Text('Bookings', style: AppTheme.bodyMedium),
                  ),
                  DropdownMenuItem(
                    value: 'revenue',
                    child: Text('Revenue', style: AppTheme.bodyMedium),
                  ),
                  DropdownMenuItem(
                    value: 'users',
                    child: Text('User Growth', style: AppTheme.bodyMedium),
                  ),
                  DropdownMenuItem(
                    value: 'ratings',
                    child: Text('Ratings', style: AppTheme.bodyMedium),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedMetric = value);
                  }
                },
              ),
            ),

            const SizedBox(height: 16),

            // Main Chart
            Container(
              height: 300,
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
              child: _buildMainChart(),
            ),

            const SizedBox(height: 24),

            // Distribution Charts
            Text(
              'Data Distribution',
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildPieChart(
                    'Tour Categories',
                    _categoryDistribution,
                    [
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.red,
                      Colors.purple,
                      Colors.teal
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPieChart(
                    'User Types',
                    _userTypeDistribution,
                    [Colors.blue, Colors.green, Colors.orange],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Additional Metrics
            Text(
              'Key Insights',
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            _buildInsightsCards(),
          ],
        ),
      ),
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
}
