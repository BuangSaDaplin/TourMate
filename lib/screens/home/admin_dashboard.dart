import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourmate_app/services/auth_service.dart';
import 'package:tourmate_app/services/notification_service.dart';
import 'package:tourmate_app/screens/auth/login_screen.dart';
import '../../utils/app_theme.dart';

// Import all admin screens
import '../admin/admin_overview_screen.dart';
import '../admin/admin_user_management_screen.dart';
import '../admin/admin_guide_verification_screen.dart';
import '../admin/admin_tour_moderation_screen.dart';
import '../admin/admin_booking_monitoring_screen.dart';
import '../admin/admin_payment_management_screen.dart';
import '../admin/admin_messaging_monitor_screen.dart';
import '../admin/admin_reviews_management_screen.dart';
import '../admin/admin_notifications_screen.dart';
import '../admin/admin_analytics_screen.dart';
import '../admin/admin_system_settings_screen.dart';
import '../admin/admin_access_control_screen.dart';
import '../admin/admin_access_wrapper.dart';
import '../profile/profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminOverviewScreen(),
    const AdminUserManagementScreen(),
    const AdminGuideVerificationScreen(),
    const AdminTourModerationScreen(),
    const AdminBookingMonitoringScreen(),
    const AdminPaymentManagementScreen(),
    const AdminMessagingMonitorScreen(),
    const AdminReviewsManagementScreen(),
    const AdminNotificationsScreen(),
    const AdminAnalyticsScreen(),
    const AdminSystemSettingsScreen(),
  ];

  final List<Map<String, dynamic>> _navigationItems = [
    {
      'icon': Icons.dashboard,
      'label': 'Dashboard',
      'color': AppTheme.primaryColor
    },
    {
      'icon': Icons.people,
      'label': 'User Management',
      'color': AppTheme.primaryColor
    },
    {
      'icon': Icons.verified_user,
      'label': 'Guide Verification',
      'color': AppTheme.accentColor
    },
    {
      'icon': Icons.tour,
      'label': 'Tour Moderation',
      'color': AppTheme.successColor
    },
    {
      'icon': Icons.book_online,
      'label': 'Booking Management',
      'color': AppTheme.primaryColor
    },
    {
      'icon': Icons.payment,
      'label': 'Payment Management',
      'color': AppTheme.errorColor
    },
    {
      'icon': Icons.chat,
      'label': 'Message Monitoring',
      'color': AppTheme.accentColor
    },
    {
      'icon': Icons.rate_review,
      'label': 'Reviews & Ratings',
      'color': AppTheme.accentColor
    },
    {
      'icon': Icons.notifications,
      'label': 'Notifications',
      'color': AppTheme.primaryColor
    },
    {
      'icon': Icons.analytics,
      'label': 'Analytics',
      'color': AppTheme.successColor
    },
    {
      'icon': Icons.settings,
      'label': 'System Settings',
      'color': AppTheme.textSecondary
    },
  ];

  void _onNavigationTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminAccessWrapper(
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.admin_panel_settings,
                    color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              const Text('Admin Panel'),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppTheme.primaryColor,
          actions: [
            // Notifications
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
                    setState(() {
                      _selectedIndex = 7; // Notifications index
                    });
                  },
                );
              },
            ),
            // Profile Menu
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'profile':
                    _navigateToProfile();
                    break;
                  case 'settings':
                    setState(() {
                      _selectedIndex =
                          10; // System Settings index (updated since we added profile)
                    });
                    break;
                  case 'logout':
                    _showLogoutDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person),
                      SizedBox(width: 8),
                      Text('Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 8),
                      Text('Settings'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: AppTheme.errorColor),
                      SizedBox(width: 8),
                      Text('Logout',
                          style: TextStyle(color: AppTheme.errorColor)),
                    ],
                  ),
                ),
              ],
              child: const CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Icon(Icons.admin_panel_settings, color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Row(
          children: [
            // Sidebar Navigation
            Container(
              width: 280,
              color: Colors.white,
              child: Column(
                children: [
                  // Navigation Items
                  Expanded(
                    child: ListView.builder(
                      itemCount: _navigationItems.length,
                      itemBuilder: (context, index) {
                        final item = _navigationItems[index];
                        final isSelected = _selectedIndex == index;

                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? item['color'].withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: Icon(
                              item['icon'],
                              color: isSelected
                                  ? item['color']
                                  : AppTheme.textSecondary,
                            ),
                            title: Text(
                              item['label'],
                              style: TextStyle(
                                color: isSelected
                                    ? item['color']
                                    : AppTheme.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            onTap: () => _onNavigationTap(index),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.admin_panel_settings,
                                size: 16, color: AppTheme.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              'Admin Access',
                              style: AppTheme.bodySmall
                                  .copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: Container(
                color: AppTheme.backgroundColor,
                child: _pages[_selectedIndex],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
              'Are you sure you want to logout from the admin panel?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await _authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
