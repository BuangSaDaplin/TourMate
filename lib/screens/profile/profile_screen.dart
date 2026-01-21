import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:tourmate_app/screens/payments/payment_history_screen.dart';
import 'package:tourmate_app/screens/verification/verification_screen.dart';
import 'package:tourmate_app/services/auth_service.dart';
import 'package:tourmate_app/services/user_profile_service.dart';
import 'package:tourmate_app/models/user_model.dart';
import 'package:tourmate_app/providers/language_provider.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';
import '../auth/terms_and_conditions_screen.dart';
import '../auth/privacy_policy_screen.dart';
import '../auth/email_verification_screen.dart';
import '../notifications/notification_screen.dart';
import 'tourist_edit_account_screen.dart';
import 'change_password_screen.dart';
import 'guide_edit_account_screen.dart';
import 'admin_edit_account_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final UserProfileService _profileService = UserProfileService();

  UserModel? _userProfile;
  bool _isLoading = true;

  String _selectedLanguage = 'English';
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _activeStatus = true; // Default to online

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userProfile = await _profileService.getCompleteUserProfile(user.uid);
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
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
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              // Handle language selection
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Language selection coming soon!'),
                ),
              );
            },
            tooltip: 'Language',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: (_userProfile?.photoURL != null &&
                            _userProfile!.photoURL!.isNotEmpty)
                        ? NetworkImage(_userProfile!.photoURL!)
                        : null,
                    child: (_userProfile?.photoURL == null ||
                            _userProfile!.photoURL!.isEmpty)
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userProfile?.displayName ?? 'Guest User',
                    style: AppTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userProfile?.email ?? 'No email',
                    style: AppTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userProfile?.createdAt != null
                        ? 'Member since ${_userProfile!.createdAt!.toLocal().year}'
                        : 'Member',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _userProfile?.role == 'guide'
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(
                              _userProfile?.toursCompleted?.toString() ?? '0',
                              'Tours Completed',
                              Icons.check_circle,
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: AppTheme.dividerColor,
                            ),
                            _buildStatItem(
                              _userProfile?.averageRating?.toStringAsFixed(1) ??
                                  '0.0',
                              'Average Rating',
                              Icons.star,
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: AppTheme.dividerColor,
                            ),
                            _buildStatItem(
                              _userProfile?.activeStatus == 1
                                  ? 'Online'
                                  : 'Offline',
                              'Status',
                              _userProfile?.activeStatus == 1
                                  ? Icons.circle
                                  : Icons.circle_outlined,
                            ),
                          ],
                        )
                      : const SizedBox(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Email Verification Section (only for tourist users with pending status)
            if (_userProfile?.role == 'tourist' &&
                _userProfile?.status == UserStatus.pending)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          color: Colors.orange.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Email Verification Required',
                            style: AppTheme.headlineSmall.copyWith(
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please verify your email address to access all features of the app.',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EmailVerificationScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Verify Email'),
                      ),
                    ),
                  ],
                ),
              ),
            if (_userProfile?.role == 'tourist' &&
                _userProfile?.status == UserStatus.pending)
              const SizedBox(height: 16),
            // Account Information
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Account Information',
                        style: AppTheme.headlineSmall,
                      ),
                      IconButton(
                        onPressed: () {
                          if (_userProfile != null) {
                            Widget editScreen;
                            switch (_userProfile!.role) {
                              case 'Tour Guide':
                                editScreen = const GuideEditAccountScreen();
                                break;
                              case 'admin':
                                editScreen = AdminEditAccountScreen(
                                  user: _userProfile!,
                                );
                                break;
                              default:
                                editScreen = const TouristEditAccountScreen();
                            }
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (context) => editScreen,
                                  ),
                                )
                                .then((_) => _loadUserProfile());
                            print('PHOTO URL: ${_userProfile?.photoURL}');
                          }
                        },
                        icon: const Icon(
                          Icons.edit,
                          size: 20,
                          color: AppTheme.primaryColor,
                        ),
                        tooltip: 'Edit Account',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.person,
                    'Full Name',
                    _userProfile?.displayName ?? 'Guest User',
                  ),
                  _buildInfoRow(
                    Icons.email,
                    'Email',
                    _userProfile?.email ?? 'No email',
                  ),
                  _buildInfoRow(
                    Icons.phone,
                    'Phone',
                    _userProfile?.phoneNumber ?? 'Not provided',
                  ),
                  if (_userProfile?.role != 'admin') ...[
                    _buildInfoRow(
                      Icons.category,
                      'Category',
                      _userProfile?.category?.join(', ') ?? 'Not set',
                    ),
                    _buildInfoRow(
                      Icons.language,
                      'Languages',
                      _userProfile?.languages?.join(', ') ?? 'English',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _userProfile?.role != 'admin'
                ? Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('App Settings', style: AppTheme.headlineSmall),
                        const SizedBox(height: 16),
                        // Language Selection
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.language,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          title: const Text('Language'),
                          subtitle: Text(_selectedLanguage),
                          trailing: DropdownButton<String>(
                            // Update value based on current provider state
                            value: Provider.of<LanguageProvider>(
                                      context,
                                    ).currentLocale.languageCode ==
                                    'tl'
                                ? 'Tagalog'
                                : 'English',
                            underline: Container(),
                            // REMOVED Cebuano from this list
                            items: ['English', 'Tagalog']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedLanguage = newValue;
                                });

                                // Map Selection to Locale Code
                                String code =
                                    (newValue == 'Tagalog') ? 'tl' : 'en';

                                // TRIGGER THE CHANGE
                                Provider.of<LanguageProvider>(
                                  context,
                                  listen: false,
                                ).changeLanguage(code);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Language switched to $newValue',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const Divider(),
                        // Push Notifications
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.notifications,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          title: const Text('Push Notifications'),
                          subtitle: const Text(
                            'Receive tour updates and reminders',
                          ),
                          value: _notificationsEnabled,
                          onChanged: (bool value) {
                            setState(() {
                              _notificationsEnabled = value;
                            });
                          },
                        ),
                        const Divider(),
                        // Active Status
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _activeStatus
                                  ? Icons.circle
                                  : Icons.circle_outlined,
                              color: _activeStatus
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                            ),
                          ),
                          title: const Text('Active Status'),
                          subtitle: Text(
                            _activeStatus
                                ? 'Online - Available for tours'
                                : 'Offline - Not available',
                          ),
                          value: _activeStatus,
                          onChanged: (bool value) {
                            setState(() {
                              _activeStatus = value;
                            });
                            // TODO: Update active status in database
                          },
                        ),
                      ],
                    ),
                  )
                : const SizedBox(),
            const SizedBox(height: 16),
            _userProfile?.role != 'admin'
                ? Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      children: [
                        _buildOptionTile(
                          Icons.payment,
                          'Payment History',
                          'View your payment history',
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PaymentHistoryScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        _buildOptionTile(
                          Icons.help,
                          'Help & Support',
                          'Get help with your bookings',
                          () {
                            // Navigate to help
                          },
                        ),
                        const Divider(),
                        _buildOptionTile(
                          Icons.lock,
                          'Change Password',
                          'Update your account password',
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ChangePasswordScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        _buildOptionTile(
                          Icons.privacy_tip,
                          'Privacy Policy',
                          'Read our privacy policy',
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PrivacyPolicyScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        _buildOptionTile(
                          Icons.description,
                          'Terms and Conditions',
                          'Read our terms and conditions before booking',
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TermsOfServiceScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                : const SizedBox(),
            const SizedBox(height: 24),
            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () {
                  _showLogoutDialog();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTheme.headlineSmall.copyWith(color: AppTheme.primaryColor),
        ),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: AppTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showDeactivateDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Deactivate Account'),
          content: const Text(
            'Are you sure you want to deactivate your account? '
            'You can reactivate it later by contacting support. '
            'This will temporarily disable your access to the platform.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                try {
                  await _authService.softDeactivateAccount();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error deactivating account: ${e.toString()}',
                        ),
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
              child: const Text('Deactivate'),
            ),
          ],
        );
      },
    );
  }
}
