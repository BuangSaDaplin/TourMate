import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/app_theme.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  String _selectedTimeRange = '7d'; // 7d, 30d, 90d, 1y
  String _selectedMetric = 'bookings'; // bookings, revenue, users, ratings

  // Mock data - replace with actual data from your backend
  final Map<String, dynamic> _analyticsData = {
    'totalBookings': 1250,
    'totalRevenue': 45280.50,
    'totalUsers': 3200,
    'activeTours': 89,
    'avgRating': 4.6,
    'bookingGrowth': 12.5,
    'revenueGrowth': 18.3,
    'userGrowth': 8.7,
  };

  // Mock time series data
  final List<Map<String, dynamic>> _bookingTrends = [
    {'date': '2024-09-01', 'bookings': 45, 'revenue': 1250.00},
    {'date': '2024-09-02', 'bookings': 52, 'revenue': 1420.00},
    {'date': '2024-09-03', 'bookings': 38, 'revenue': 980.00},
    {'date': '2024-09-04', 'bookings': 61, 'revenue': 1680.00},
    {'date': '2024-09-05', 'bookings': 49, 'revenue': 1320.00},
    {'date': '2024-09-06', 'bookings': 55, 'revenue': 1490.00},
    {'date': '2024-09-07', 'bookings': 67, 'revenue': 1820.00},
  ];

  final List<Map<String, dynamic>> _ratingTrends = [
    {'date': '2024-09-01', 'avgRating': 4.2, 'totalReviews': 23},
    {'date': '2024-09-02', 'avgRating': 4.4, 'totalReviews': 28},
    {'date': '2024-09-03', 'avgRating': 4.1, 'totalReviews': 19},
    {'date': '2024-09-04', 'avgRating': 4.6, 'totalReviews': 31},
    {'date': '2024-09-05', 'avgRating': 4.3, 'totalReviews': 25},
    {'date': '2024-09-06', 'avgRating': 4.5, 'totalReviews': 29},
    {'date': '2024-09-07', 'avgRating': 4.7, 'totalReviews': 35},
  ];

  final Map<String, int> _categoryDistribution = {
    'Adventure': 25,
    'Culture': 20,
    'Food': 15,
    'Nature': 18,
    'Beach': 12,
    'City Tour': 10,
  };

  final Map<String, int> _userTypeDistribution = {
    'Tourists': 68,
    'Tour Guides': 22,
    'Admins': 10,
  };

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
                  const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
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
                    [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.teal],
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

  Widget _buildKPICard(String title, String value, IconData icon, Color color, String change) {
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
          _bookingTrends.map((data) => FlSpot(
            _bookingTrends.indexOf(data).toDouble(),
            data['bookings'].toDouble(),
          )).toList(),
          'Daily Bookings',
          Colors.blue,
        );
      case 'revenue':
        return _buildLineChart(
          _bookingTrends.map((data) => FlSpot(
            _bookingTrends.indexOf(data).toDouble(),
            data['revenue'],
          )).toList(),
          'Daily Revenue (\$)',
          Colors.green,
        );
      case 'ratings':
        return _buildLineChart(
          _ratingTrends.map((data) => FlSpot(
            _ratingTrends.indexOf(data).toDouble(),
            data['avgRating'],
          )).toList(),
          'Average Rating',
          Colors.orange,
        );
      default:
        return _buildLineChart(
          _bookingTrends.map((data) => FlSpot(
            _bookingTrends.indexOf(data).toDouble(),
            data['bookings'].toDouble(),
          )).toList(),
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

  Widget _buildPieChart(String title, Map<String, int> data, List<Color> colors) {
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
          Text(title, style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
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
            final color = colors[(data.keys.toList().indexOf(entry.key)) % colors.length];
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
                    style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
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

  Widget _buildInsightCard(String title, String value, String subtitle, IconData icon, Color color) {
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