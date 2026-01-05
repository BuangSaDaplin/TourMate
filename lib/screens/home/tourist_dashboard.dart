import 'package:flutter/material.dart';
import 'package:tourmate_app/screens/messaging/conversations_screen.dart';
import 'package:tourmate_app/screens/notifications/notification_screen.dart';

class TouristDashboard extends StatelessWidget {
  const TouristDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tourist Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ConversationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Tourist Dashboard'),
      ),
    );
  }
}
