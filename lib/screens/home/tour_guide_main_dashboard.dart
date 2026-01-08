import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../guide/tour_guide_dashboard_tab.dart';
import '../guide/tours_management_screen.dart';
import '../guide/bookings_management_screen.dart';
import '../guide/messages_screen.dart';
import '../guide/tour_guide_profile_screen.dart';
import '../guide/tour_guide_notifications_screen.dart';
import '../../widgets/auto_translated_text.dart';

class TourGuideMainDashboard extends StatefulWidget {
  const TourGuideMainDashboard({super.key});

  @override
  State<TourGuideMainDashboard> createState() => _TourGuideMainDashboardState();
}

class _TourGuideMainDashboardState extends State<TourGuideMainDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const TourGuideDashboardTab(),
    const ToursManagementScreen(),
    const BookingsManagementScreen(),
    const MessagesScreen(),
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
      appBar: AppBar(
        title: AutoTranslatedText(_titles[_selectedIndex]),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TourGuideNotificationsScreen(),
                ),
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
