import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_theme.dart';
import '../guide/tour_guide_dashboard_tab.dart';
import '../guide/tours_management_screen.dart';
import '../guide/bookings_management_screen.dart';
import '../messaging/conversations_screen.dart';
import '../guide/tour_guide_profile_screen.dart';
import '../guide/tour_guide_notifications_screen.dart';
import '../../widgets/auto_translated_text.dart';
import '../../services/notification_service.dart';

class TourGuideMainDashboard extends StatefulWidget {
  const TourGuideMainDashboard({super.key});

  @override
  State<TourGuideMainDashboard> createState() => _TourGuideMainDashboardState();
}

class _TourGuideMainDashboardState extends State<TourGuideMainDashboard> {
  int _selectedIndex = 0;
  final NotificationService _notificationService = NotificationService();

  final List<Widget> _pages = [
    const TourGuideDashboardTab(),
    const ToursManagementScreen(),
    const BookingsManagementScreen(),
    const ConversationsScreen(),
    const TourGuideProfileScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Tours',
    'Bookings',
    'Messages',
    'Profile',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _selectedIndex == 3
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              title: AutoTranslatedText(_titles[_selectedIndex]),
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              actions: [
                StreamBuilder<int>(
                  stream: FirebaseAuth.instance.currentUser != null
                      ? _notificationService.getUnreadCount(
                          FirebaseAuth.instance.currentUser!.uid)
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
                            builder: (context) =>
                                const TourGuideNotificationsScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.language),
                  onSelected: (value) {
                    if (value == 'tl') {
                      isTagalogNotifier.value = true; // Switch to Tagalog
                    } else {
                      isTagalogNotifier.value = false; // Switch to English
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'en', child: Text('English')),
                    // const PopupMenuItem(value: 'ceb', child: Text('Cebuano')), // Hide if not supported
                    const PopupMenuItem(value: 'tl', child: Text('Tagalog')),
                  ],
                ),
              ],
            ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tour),
            label: 'Tours',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
