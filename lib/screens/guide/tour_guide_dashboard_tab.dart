import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'create_tour_screen.dart';
import 'bookings_management_screen.dart';
import 'guide_submit_credentials_screen.dart';

class TourGuideDashboardTab extends StatelessWidget {
  const TourGuideDashboardTab({super.key});

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
                  'Welcome back, Juan!',
                  style: AppTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ready to guide more tourists today?',
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
           ),
           const SizedBox(height: 16),

           // Verification Status Banner
           Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               color: AppTheme.accentColor.withOpacity(0.1),
               borderRadius: BorderRadius.circular(12),
               border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
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
                         builder: (context) => const GuideSubmitCredentialsScreen(),
                       ),
                     );
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppTheme.accentColor,
                     foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   ),
                   child: const Text('Submit Now'),
                 ),
               ],
             ),
           ),
           const SizedBox(height: 24),

          // Stats Overview
          Text('Overview', style: AppTheme.headlineSmall),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Active Tours',
                  '3',
                  Icons.tour,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Earnings',
                  '₱12,500',
                  Icons.attach_money,
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
                  '4.8',
                  Icons.star,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Requests',
                  '5',
                  Icons.notifications,
                  AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Actions
          Text('Quick Actions', style: AppTheme.headlineSmall),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Create Tour',
                  Icons.add,
                  () {
                    // Navigate to create tour screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateTourScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'View Requests',
                  Icons.calendar_today,
                  () {
                    // Navigate to bookings management screen - Requests tab
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BookingsManagementScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Activity
          Text('Recent Activity', style: AppTheme.headlineSmall),
          const SizedBox(height: 16),
          _buildActivityItem(
            'New booking request for Kawasan Falls tour',
            '2 hours ago',
            Icons.calendar_today,
          ),
          _buildActivityItem(
            'Payment received for Oslob tour',
            '5 hours ago',
            Icons.attach_money,
          ),
          _buildActivityItem(
            'New 5-star review received',
            '1 day ago',
            Icons.star,
          ),
          _buildActivityItem(
            'Tour completed: Bantayan Island',
            '2 days ago',
            Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
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

  Widget _buildActionButton(
      String title, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon) {
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
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
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
}
