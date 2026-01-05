import 'package:flutter/material.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide Verification Requests'),
      ),
      body: ListView.builder(
        itemCount: 10, // Replace with actual data
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text('User ${index + 1}'),
              subtitle: const Text('Pending Verification'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () {
                      // Handle approve
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      // Handle reject
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
