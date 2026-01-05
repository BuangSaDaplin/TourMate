import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // Notification settings
  bool _bookingNotifications = true;
  bool _paymentNotifications = true;
  bool _messageNotifications = true;
  bool _reviewNotifications = true;
  bool _systemNotifications = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  // Bulk notification form
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  NotificationType _selectedType = NotificationType.system;
  NotificationPriority _selectedPriority = NotificationPriority.normal;
  bool _sendToAllUsers = false;
  List<String> _selectedUserIds = [];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Notification Management'),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Settings'),
              Tab(text: 'Send'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSettingsTab(),
            _buildSendTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Global Notification Settings',
            style: AppTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Configure default notification preferences for all users',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          _buildSettingCard(
            'Push Notifications',
            'Send push notifications to user devices',
            _pushNotifications,
            (value) => setState(() => _pushNotifications = value),
          ),
          _buildSettingCard(
            'Email Notifications',
            'Send email notifications for important updates',
            _emailNotifications,
            (value) => setState(() => _emailNotifications = value),
          ),
          const SizedBox(height: 32),
          Text(
            'Notification Types',
            style: AppTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            'Booking Notifications',
            'Alerts for new bookings, cancellations, and updates',
            _bookingNotifications,
            (value) => setState(() => _bookingNotifications = value),
          ),
          _buildSettingCard(
            'Payment Notifications',
            'Alerts for payment processing and receipts',
            _paymentNotifications,
            (value) => setState(() => _paymentNotifications = value),
          ),
          _buildSettingCard(
            'Message Notifications',
            'Alerts for new messages and conversations',
            _messageNotifications,
            (value) => setState(() => _messageNotifications = value),
          ),
          _buildSettingCard(
            'Review Notifications',
            'Alerts for new reviews and ratings',
            _reviewNotifications,
            (value) => setState(() => _reviewNotifications = value),
          ),
          _buildSettingCard(
            'System Notifications',
            'Important system updates and maintenance alerts',
            _systemNotifications,
            (value) => setState(() => _systemNotifications = value),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildSendTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send Bulk Notification',
            style: AppTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Send notifications to multiple users at once',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Notification Title',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _messageController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notification Message',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter a message';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<NotificationType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Notification Type',
                    border: OutlineInputBorder(),
                  ),
                  items: NotificationType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child:
                          Text(type.toString().split('.').last.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<NotificationPriority>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: NotificationPriority.values.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(
                          priority.toString().split('.').last.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPriority = value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Send to all users'),
            subtitle:
                const Text('Send this notification to every registered user'),
            value: _sendToAllUsers,
            onChanged: (value) {
              setState(() => _sendToAllUsers = value ?? false);
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _sendBulkNotification,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Send Notification'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _previewNotification,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Preview Notification'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<NotificationModel>>(
      stream: _notificationService.getUserNotifications(_currentUserId ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading notifications: ${snapshot.error}'),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications sent yet',
                  style: AppTheme.headlineSmall,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: notification.color.withOpacity(0.1),
                  child: Icon(notification.icon, color: notification.color),
                ),
                title: Text(notification.title),
                subtitle:
                    Text('${notification.message}\n${notification.timeAgo}'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteNotification(notification.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingCard(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title,
            style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: AppTheme.bodySmall),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  void _saveSettings() {
    // Save notification settings to Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification settings saved successfully')),
    );
  }

  void _sendBulkNotification() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      // Get all user IDs from database or selected user IDs
      final userIds =
          _sendToAllUsers ? await _getAllUserIds() : _selectedUserIds;

      await _notificationService.sendBulkNotification(
        userIds: userIds,
        title: _titleController.text,
        message: _messageController.text,
        type: _selectedType,
        priority: _selectedPriority,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bulk notification sent successfully')),
      );

      // Clear form
      _titleController.clear();
      _messageController.clear();
      setState(() {
        _selectedType = NotificationType.system;
        _selectedPriority = NotificationPriority.normal;
        _sendToAllUsers = false;
        _selectedUserIds = [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending notification: $e')),
      );
    }
  }

  Future<List<String>> _getAllUserIds() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user IDs: $e')),
      );
      return [];
    }
  }

  void _previewNotification() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${_titleController.text}', style: AppTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('Message: ${_messageController.text}',
                style: AppTheme.bodyMedium),
            const SizedBox(height: 8),
            Text('Type: ${_selectedType.toString().split('.').last}',
                style: AppTheme.bodySmall),
            Text('Priority: ${_selectedPriority.toString().split('.').last}',
                style: AppTheme.bodySmall),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting notification: $e')),
      );
    }
  }
}
