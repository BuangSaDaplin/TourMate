import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key});

  // Mock data - replace with actual data fetching
  static const int totalUsers = 1250;
  static const int pendingVerifications = 15;
  static const int activeTours = 89;
  static const double monthlyRevenue = 15420.50;
  static const int totalBookings = 342;
  static const double averageRating = 4.7;

  @override
  Widget build(BuildContext context) {
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
                  totalUsers.toString(),
                  Icons.people,
                  AppTheme.primaryColor,
                  '+12% from last month',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildKPICard(
                  'Active Tours',
                  activeTours.toString(),
                  Icons.tour,
                  AppTheme.successColor,
                  '+8% from last month',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildKPICard(
                  'Total Bookings',
                  totalBookings.toString(),
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
                  'Monthly Revenue',
                  '\$${monthlyRevenue.toStringAsFixed(0)}',
                  Icons.attach_money,
                  AppTheme.errorColor,
                  '+22% from last month',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildKPICard(
                  'Pending Verifications',
                  pendingVerifications.toString(),
                  Icons.verified_user,
                  AppTheme.primaryColor,
                  'Requires attention',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildKPICard(
                  'Average Rating',
                  averageRating.toString(),
                  Icons.star,
                  AppTheme.successColor,
                  'Platform rating',
                ),
              ),
            ],
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
                        Row(
                          children: [
                            Icon(Icons.show_chart, color: AppTheme.primaryColor),
                            const SizedBox(width: 12),
                            Text(
                              'Bookings Trend',
                              style: AppTheme.headlineSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Placeholder for chart
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              '📊 Chart Placeholder\n\nTODO: Integrate with charting library\n(fl_chart or syncfusion_charts)',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Last 30 days booking activity',
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),

              // Quick Actions
              Expanded(
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
                          'Quick Actions',
                          style: AppTheme.headlineSmall,
                        ),
                        const SizedBox(height: 24),
                        _buildQuickAction(
                          'Review Verifications',
                          '15 pending requests',
                          Icons.verified_user,
                          AppTheme.accentColor,
                        ),
                        const SizedBox(height: 16),
                        _buildQuickAction(
                          'Moderate Tours',
                          '3 flagged listings',
                          Icons.tour,
                          AppTheme.errorColor,
                        ),
                        const SizedBox(height: 16),
                        _buildQuickAction(
                          'View Reports',
                          'Generate analytics',
                          Icons.analytics,
                          AppTheme.successColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
                  _buildActivityItem(
                    'New user registration',
                    'John Doe registered as a Tourist',
                    '2 hours ago',
                    Icons.person_add,
                  ),
                  _buildActivityItem(
                    'Verification approved',
                    'Jane Smith\'s guide application approved',
                    '4 hours ago',
                    Icons.verified,
                  ),
                  _buildActivityItem(
                    'Tour created',
                    'Mike Johnson created "City Walking Tour"',
                    '6 hours ago',
                    Icons.add_circle,
                  ),
                  _buildActivityItem(
                    'Payment processed',
                    'Booking #1234 payment completed',
                    '8 hours ago',
                    Icons.payment,
                  ),
                  _buildActivityItem(
                    'Review submitted',
                    'New 5-star review for "Mountain Hiking Tour"',
                    '10 hours ago',
                    Icons.rate_review,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color, String subtitle) {
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

  Widget _buildQuickAction(String title, String subtitle, IconData icon, Color color) {
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
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: color),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon) {
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
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
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