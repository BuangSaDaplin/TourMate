import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_theme.dart';

class AdminSystemSettingsScreen extends StatefulWidget {
  const AdminSystemSettingsScreen({super.key});

  @override
  State<AdminSystemSettingsScreen> createState() => _AdminSystemSettingsScreenState();
}

class _AdminSystemSettingsScreenState extends State<AdminSystemSettingsScreen> {
  // System Configuration Settings
  bool _maintenanceMode = false;
  bool _registrationEnabled = true;
  bool _emailVerificationRequired = false;
  bool _tourCreationRequiresApproval = false;
  bool _autoBackupEnabled = true;
  int _sessionTimeoutMinutes = 30;
  int _maxLoginAttempts = 5;
  double _platformFeePercentage = 5.0;
  String _supportEmail = 'support@tourmate.com';
  String _currency = 'PHP';

  // Feature Toggles
  bool _messagingEnabled = true;
  bool _reviewsEnabled = true;
  bool _bookingSystemEnabled = true;
  bool _paymentSystemEnabled = true;
  bool _analyticsEnabled = true;

  // Security Settings
  bool _twoFactorAuthRequired = false;
  bool _ipWhitelistEnabled = false;
  int _passwordMinLength = 8;
  bool _passwordRequireSpecialChars = true;
  bool _passwordRequireNumbers = true;

  // Notification Settings
  bool _adminEmailNotifications = true;
  bool _systemAlertNotifications = true;
  bool _userActivityNotifications = false;

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _maintenanceMode = prefs.getBool('maintenanceMode') ?? false;
      _registrationEnabled = prefs.getBool('registrationEnabled') ?? true;
      _emailVerificationRequired = prefs.getBool('emailVerificationRequired') ?? false;
      _tourCreationRequiresApproval = prefs.getBool('tourCreationRequiresApproval') ?? false;
      _autoBackupEnabled = prefs.getBool('autoBackupEnabled') ?? true;
      _sessionTimeoutMinutes = prefs.getInt('sessionTimeoutMinutes') ?? 30;
      _maxLoginAttempts = prefs.getInt('maxLoginAttempts') ?? 5;
      _platformFeePercentage = prefs.getDouble('platformFeePercentage') ?? 5.0;
      _supportEmail = prefs.getString('supportEmail') ?? 'support@tourmate.com';
      _currency = prefs.getString('currency') ?? 'PHP';

      _messagingEnabled = prefs.getBool('messagingEnabled') ?? true;
      _reviewsEnabled = prefs.getBool('reviewsEnabled') ?? true;
      _bookingSystemEnabled = prefs.getBool('bookingSystemEnabled') ?? true;
      _paymentSystemEnabled = prefs.getBool('paymentSystemEnabled') ?? true;
      _analyticsEnabled = prefs.getBool('analyticsEnabled') ?? true;

      _twoFactorAuthRequired = prefs.getBool('twoFactorAuthRequired') ?? false;
      _ipWhitelistEnabled = prefs.getBool('ipWhitelistEnabled') ?? false;
      _passwordMinLength = prefs.getInt('passwordMinLength') ?? 8;
      _passwordRequireSpecialChars = prefs.getBool('passwordRequireSpecialChars') ?? true;
      _passwordRequireNumbers = prefs.getBool('passwordRequireNumbers') ?? true;

      _adminEmailNotifications = prefs.getBool('adminEmailNotifications') ?? true;
      _systemAlertNotifications = prefs.getBool('systemAlertNotifications') ?? true;
      _userActivityNotifications = prefs.getBool('userActivityNotifications') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('maintenanceMode', _maintenanceMode);
    await prefs.setBool('registrationEnabled', _registrationEnabled);
    await prefs.setBool('emailVerificationRequired', _emailVerificationRequired);
    await prefs.setBool('tourCreationRequiresApproval', _tourCreationRequiresApproval);
    await prefs.setBool('autoBackupEnabled', _autoBackupEnabled);
    await prefs.setInt('sessionTimeoutMinutes', _sessionTimeoutMinutes);
    await prefs.setInt('maxLoginAttempts', _maxLoginAttempts);
    await prefs.setDouble('platformFeePercentage', _platformFeePercentage);
    await prefs.setString('supportEmail', _supportEmail);
    await prefs.setString('currency', _currency);

    await prefs.setBool('messagingEnabled', _messagingEnabled);
    await prefs.setBool('reviewsEnabled', _reviewsEnabled);
    await prefs.setBool('bookingSystemEnabled', _bookingSystemEnabled);
    await prefs.setBool('paymentSystemEnabled', _paymentSystemEnabled);
    await prefs.setBool('analyticsEnabled', _analyticsEnabled);

    await prefs.setBool('twoFactorAuthRequired', _twoFactorAuthRequired);
    await prefs.setBool('ipWhitelistEnabled', _ipWhitelistEnabled);
    await prefs.setInt('passwordMinLength', _passwordMinLength);
    await prefs.setBool('passwordRequireSpecialChars', _passwordRequireSpecialChars);
    await prefs.setBool('passwordRequireNumbers', _passwordRequireNumbers);

    await prefs.setBool('adminEmailNotifications', _adminEmailNotifications);
    await prefs.setBool('systemAlertNotifications', _systemAlertNotifications);
    await prefs.setBool('userActivityNotifications', _userActivityNotifications);

    setState(() => _hasChanges = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('System settings saved successfully')),
      );
    }
  }

  void _markAsChanged() {
    setState(() => _hasChanges = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('System Settings'),
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
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'General'),
                Tab(text: 'Features'),
                Tab(text: 'Security'),
                Tab(text: 'Notifications'),
              ],
              isScrollable: true,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildGeneralTab(),
                  _buildFeaturesTab(),
                  _buildSecurityTab(),
                  _buildNotificationsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('General Configuration', style: AppTheme.headlineSmall),
          const SizedBox(height: 16),

          _buildSwitchSetting(
            'Maintenance Mode',
            'Put the platform in maintenance mode',
            _maintenanceMode,
            (value) => setState(() => _maintenanceMode = value),
          ),

          _buildSwitchSetting(
            'User Registration',
            'Allow new users to register',
            _registrationEnabled,
            (value) => setState(() => _registrationEnabled = value),
          ),

          _buildSwitchSetting(
            'Email Verification Required',
            'Require email verification for new accounts',
            _emailVerificationRequired,
            (value) => setState(() => _emailVerificationRequired = value),
          ),

          _buildSwitchSetting(
            'Tour Approval Required',
            'Require admin approval for new tours',
            _tourCreationRequiresApproval,
            (value) => setState(() => _tourCreationRequiresApproval = value),
          ),

          _buildSwitchSetting(
            'Auto Backup',
            'Automatically backup system data',
            _autoBackupEnabled,
            (value) => setState(() => _autoBackupEnabled = value),
          ),

          const SizedBox(height: 24),
          Text('Platform Settings', style: AppTheme.headlineSmall),
          const SizedBox(height: 16),

          _buildTextFieldSetting(
            'Support Email',
            _supportEmail,
            (value) => setState(() => _supportEmail = value),
            keyboardType: TextInputType.emailAddress,
          ),

          _buildDropdownSetting(
            'Currency',
            _currency,
            ['PHP', 'USD', 'EUR'],
            (value) => setState(() => _currency = value!),
          ),

          _buildSliderSetting(
            'Platform Fee (%)',
            _platformFeePercentage,
            0,
            20,
            (value) => setState(() => _platformFeePercentage = value),
          ),

          _buildNumberFieldSetting(
            'Session Timeout (minutes)',
            _sessionTimeoutMinutes,
            (value) => setState(() => _sessionTimeoutMinutes = value),
            min: 5,
            max: 480,
          ),

          _buildNumberFieldSetting(
            'Max Login Attempts',
            _maxLoginAttempts,
            (value) => setState(() => _maxLoginAttempts = value),
            min: 3,
            max: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Feature Toggles', style: AppTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Enable or disable platform features',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          _buildSwitchSetting(
            'Messaging System',
            'Allow users to send messages',
            _messagingEnabled,
            (value) => setState(() => _messagingEnabled = value),
          ),

          _buildSwitchSetting(
            'Review System',
            'Allow users to leave reviews',
            _reviewsEnabled,
            (value) => setState(() => _reviewsEnabled = value),
          ),

          _buildSwitchSetting(
            'Booking System',
            'Allow tour bookings',
            _bookingSystemEnabled,
            (value) => setState(() => _bookingSystemEnabled = value),
          ),

          _buildSwitchSetting(
            'Payment System',
            'Enable payment processing',
            _paymentSystemEnabled,
            (value) => setState(() => _paymentSystemEnabled = value),
          ),

          _buildSwitchSetting(
            'Analytics',
            'Enable platform analytics',
            _analyticsEnabled,
            (value) => setState(() => _analyticsEnabled = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Security Settings', style: AppTheme.headlineSmall),
          const SizedBox(height: 16),

          _buildSwitchSetting(
            'Two-Factor Authentication',
            'Require 2FA for admin accounts',
            _twoFactorAuthRequired,
            (value) => setState(() => _twoFactorAuthRequired = value),
          ),

          _buildSwitchSetting(
            'IP Whitelist',
            'Restrict admin access by IP address',
            _ipWhitelistEnabled,
            (value) => setState(() => _ipWhitelistEnabled = value),
          ),

          const SizedBox(height: 24),
          Text('Password Policy', style: AppTheme.headlineSmall),
          const SizedBox(height: 16),

          _buildNumberFieldSetting(
            'Minimum Password Length',
            _passwordMinLength,
            (value) => setState(() => _passwordMinLength = value),
            min: 6,
            max: 32,
          ),

          _buildSwitchSetting(
            'Require Special Characters',
            'Passwords must contain special characters',
            _passwordRequireSpecialChars,
            (value) => setState(() => _passwordRequireSpecialChars = value),
          ),

          _buildSwitchSetting(
            'Require Numbers',
            'Passwords must contain numbers',
            _passwordRequireNumbers,
            (value) => setState(() => _passwordRequireNumbers = value),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Admin Notifications', style: AppTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Configure notifications for administrators',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          _buildSwitchSetting(
            'Email Notifications',
            'Receive system notifications via email',
            _adminEmailNotifications,
            (value) => setState(() => _adminEmailNotifications = value),
          ),

          _buildSwitchSetting(
            'System Alerts',
            'Get notified of critical system events',
            _systemAlertNotifications,
            (value) => setState(() => _systemAlertNotifications = value),
          ),

          _buildSwitchSetting(
            'User Activity',
            'Receive notifications about user activities',
            _userActivityNotifications,
            (value) => setState(() => _userActivityNotifications = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title, style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: AppTheme.bodySmall),
        value: value,
        onChanged: (newValue) {
          onChanged(newValue);
          _markAsChanged();
        },
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildTextFieldSetting(String label, String value, Function(String) onChanged, {TextInputType? keyboardType}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          initialValue: value,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          keyboardType: keyboardType,
          onChanged: (newValue) {
            onChanged(newValue);
            _markAsChanged();
          },
        ),
      ),
    );
  }

  Widget _buildDropdownSetting(String label, String value, List<String> options, Function(String?) onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (newValue) {
            onChanged(newValue);
            _markAsChanged();
          },
        ),
      ),
    );
  }

  Widget _buildSliderSetting(String label, double value, double min, double max, Function(double) onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${value.toStringAsFixed(1)}%', style: AppTheme.bodyMedium),
                Expanded(
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: 40,
                    onChanged: (newValue) {
                      onChanged(newValue);
                      _markAsChanged();
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberFieldSetting(String label, int value, Function(int) onChanged, {int? min, int? max}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          initialValue: value.toString(),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (newValue) {
            final intValue = int.tryParse(newValue) ?? value;
            if (min != null && intValue < min) return;
            if (max != null && intValue > max) return;
            onChanged(intValue);
            _markAsChanged();
          },
        ),
      ),
    );
  }
}