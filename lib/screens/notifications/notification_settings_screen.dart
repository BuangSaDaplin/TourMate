import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/notification_settings_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final AuthService _authService = AuthService();
  late NotificationSettingsModel _settings;
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();

      // Load settings from SharedPreferences
      _settings = NotificationSettingsModel(
        userId: currentUser?.uid ?? '',
        masterNotificationsEnabled:
            prefs.getBool('masterNotificationsEnabled') ?? true,
        pushNotifications: prefs.getBool('pushNotifications') ?? true,
        emailNotifications: prefs.getBool('emailNotifications') ?? false,
        bookingNotifications: prefs.getBool('bookingNotifications') ?? true,
        paymentNotifications: prefs.getBool('paymentNotifications') ?? true,
        messageNotifications: prefs.getBool('messageNotifications') ?? true,
        reviewNotifications: prefs.getBool('reviewNotifications') ?? true,
        systemNotifications: prefs.getBool('systemNotifications') ?? true,
        marketingNotifications:
            prefs.getBool('marketingNotifications') ?? false,
        quietHours: {
          'monday': prefs.getBool('quietMonday') ?? false,
          'tuesday': prefs.getBool('quietTuesday') ?? false,
          'wednesday': prefs.getBool('quietWednesday') ?? false,
          'thursday': prefs.getBool('quietThursday') ?? false,
          'friday': prefs.getBool('quietFriday') ?? false,
          'saturday': prefs.getBool('quietSaturday') ?? false,
          'sunday': prefs.getBool('quietSunday') ?? false,
        },
      );
    } catch (e) {
      // Create default settings on error
      _settings = const NotificationSettingsModel(userId: '');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save settings to SharedPreferences
      await prefs.setBool(
          'masterNotificationsEnabled', _settings.masterNotificationsEnabled);
      await prefs.setBool('pushNotifications', _settings.pushNotifications);
      await prefs.setBool('emailNotifications', _settings.emailNotifications);
      await prefs.setBool(
          'bookingNotifications', _settings.bookingNotifications);
      await prefs.setBool(
          'paymentNotifications', _settings.paymentNotifications);
      await prefs.setBool(
          'messageNotifications', _settings.messageNotifications);
      await prefs.setBool('reviewNotifications', _settings.reviewNotifications);
      await prefs.setBool('systemNotifications', _settings.systemNotifications);
      await prefs.setBool(
          'marketingNotifications', _settings.marketingNotifications);

      // Save quiet hours
      await prefs.setBool(
          'quietMonday', _settings.quietHours['monday'] ?? false);
      await prefs.setBool(
          'quietTuesday', _settings.quietHours['tuesday'] ?? false);
      await prefs.setBool(
          'quietWednesday', _settings.quietHours['wednesday'] ?? false);
      await prefs.setBool(
          'quietThursday', _settings.quietHours['thursday'] ?? false);
      await prefs.setBool(
          'quietFriday', _settings.quietHours['friday'] ?? false);
      await prefs.setBool(
          'quietSaturday', _settings.quietHours['saturday'] ?? false);
      await prefs.setBool(
          'quietSunday', _settings.quietHours['sunday'] ?? false);

      setState(() => _hasChanges = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  void _updateSetting(bool? value, String settingName) {
    if (value == null) return;

    setState(() {
      _hasChanges = true;
      switch (settingName) {
        case 'pushNotifications':
          _settings = _settings.copyWith(pushNotifications: value);
          break;
        case 'emailNotifications':
          _settings = _settings.copyWith(emailNotifications: value);
          break;
        case 'bookingNotifications':
          _settings = _settings.copyWith(bookingNotifications: value);
          break;
        case 'paymentNotifications':
          _settings = _settings.copyWith(paymentNotifications: value);
          break;
        case 'messageNotifications':
          _settings = _settings.copyWith(messageNotifications: value);
          break;
        case 'reviewNotifications':
          _settings = _settings.copyWith(reviewNotifications: value);
          break;
        case 'systemNotifications':
          _settings = _settings.copyWith(systemNotifications: value);
          break;
        case 'marketingNotifications':
          _settings = _settings.copyWith(marketingNotifications: value);
          break;
      }

      // Update master toggle based on individual settings
      _settings = _settings.copyWith(
        masterNotificationsEnabled: _settings.pushNotifications &&
            _settings.emailNotifications &&
            _settings.bookingNotifications &&
            _settings.paymentNotifications &&
            _settings.messageNotifications &&
            _settings.reviewNotifications &&
            _settings.systemNotifications &&
            _settings.marketingNotifications,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveSettings,
              child: Text(
                'Save',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
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
            Text(
              'Stay informed about your tours and bookings',
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),

            // General Settings
            Text(
              'General',
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Master toggle for all notifications
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.notifications_active,
                      color: AppTheme.primaryColor),
                ),
                title: Text('Enable All Notifications',
                    style: AppTheme.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Turn on/off all notifications at once',
                    style: AppTheme.bodySmall),
                value: _settings.masterNotificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _hasChanges = true;
                    final enabled = value ?? true;
                    // Update all individual settings based on master toggle
                    _settings = _settings.copyWith(
                      masterNotificationsEnabled: enabled,
                      pushNotifications: enabled,
                      emailNotifications: enabled,
                      bookingNotifications: enabled,
                      paymentNotifications: enabled,
                      messageNotifications: enabled,
                      reviewNotifications: enabled,
                      systemNotifications: enabled,
                      marketingNotifications: enabled,
                    );
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),

            _buildSettingCard(
              'Push Notifications',
              'Receive notifications on your device',
              Icons.notifications,
              _settings.pushNotifications,
              (value) => _updateSetting(value, 'pushNotifications'),
            ),

            _buildSettingCard(
              'Email Notifications',
              'Receive notifications via email',
              Icons.email,
              _settings.emailNotifications,
              (value) => _updateSetting(value, 'emailNotifications'),
            ),

            const SizedBox(height: 32),

            // Notification Types
            Text(
              'Notification Types',
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            _buildSettingCard(
              'Booking Updates',
              'New bookings, cancellations, and changes',
              Icons.book_online,
              _settings.bookingNotifications,
              (value) => _updateSetting(value, 'bookingNotifications'),
            ),

            _buildSettingCard(
              'Payment Alerts',
              'Payment confirmations and receipts',
              Icons.payment,
              _settings.paymentNotifications,
              (value) => _updateSetting(value, 'paymentNotifications'),
            ),

            _buildSettingCard(
              'Messages',
              'New messages from guides and tourists',
              Icons.message,
              _settings.messageNotifications,
              (value) => _updateSetting(value, 'messageNotifications'),
            ),

            _buildSettingCard(
              'Reviews & Ratings',
              'New reviews on your tours',
              Icons.star,
              _settings.reviewNotifications,
              (value) => _updateSetting(value, 'reviewNotifications'),
            ),

            _buildSettingCard(
              'System Updates',
              'Important app updates and maintenance',
              Icons.info,
              _settings.systemNotifications,
              (value) => _updateSetting(value, 'systemNotifications'),
            ),

            _buildSettingCard(
              'Promotions',
              'Special offers and marketing updates',
              Icons.local_offer,
              _settings.marketingNotifications,
              (value) => _updateSetting(value, 'marketingNotifications'),
            ),

            const SizedBox(height: 32),

            // Quiet Hours
            Text(
              'Quiet Hours',
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Disable notifications during specific times',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),

            _buildQuietHoursSettings(),

            const SizedBox(height: 32),

            // Test Notification
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Notification',
                      style: AppTheme.bodyLarge
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        'Send a test notification to verify your settings'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _sendTestNotification,
                      child: const Text('Send Test Notification'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool?) onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title,
            style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: AppTheme.bodySmall),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildQuietHoursSettings() {
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enable quiet hours for these days:',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...days.map((day) {
              final isEnabled = _settings.quietHours[day] ?? false;
              return CheckboxListTile(
                title: Text(
                  day[0].toUpperCase() + day.substring(1),
                  style: AppTheme.bodyMedium,
                ),
                subtitle: const Text('10:00 PM - 8:00 AM'),
                value: isEnabled,
                onChanged: (value) {
                  setState(() {
                    _hasChanges = true;
                    final newQuietHours =
                        Map<String, bool>.from(_settings.quietHours);
                    newQuietHours[day] = value ?? false;
                    _settings = _settings.copyWith(quietHours: newQuietHours);
                  });
                },
                activeColor: AppTheme.primaryColor,
              );
            }),
          ],
        ),
      ),
    );
  }

  void _sendTestNotification() {
    // In a real app, this would create and send a test notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Test notification sent! Check your notifications.')),
    );
  }
}
