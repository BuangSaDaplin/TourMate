import 'package:flutter/material.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: ListView.builder(
        itemCount: 10, // Replace with actual data
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text('User ${index + 1}'),
              subtitle: const Text('user@example.com'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.block),
                    onPressed: () {
                      // Handle ban user
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
