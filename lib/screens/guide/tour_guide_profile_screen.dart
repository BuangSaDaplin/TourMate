import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourmate_app/screens/payments/payment_history_screen.dart';
import 'package:tourmate_app/services/auth_service.dart';
import 'package:tourmate_app/services/user_profile_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';
import '../auth/terms_and_conditions_screen.dart';
import '../auth/privacy_policy_screen.dart';
import '../notifications/notification_screen.dart';
import '../profile/change_password_screen.dart';
import '../profile/guide_edit_account_screen.dart';

class TourGuideProfileScreen extends StatefulWidget {
  const TourGuideProfileScreen({super.key});

  @override
  State<TourGuideProfileScreen> createState() => _TourGuideProfileScreenState();
}

class _TourGuideProfileScreenState extends State<TourGuideProfileScreen> {
  final AuthService _authService = AuthService();
  final UserProfileService _profileService = UserProfileService();

  UserModel? _userProfile;
  bool _isLoading = true;

  // Mock tour guide data
  final Map<String, dynamic> _guideData = {
    'name': 'Juan dela Cruz',
    'email': 'juan.guide@example.com',
    'phone': '+63 912 345 6789',
    'joinDate': 'Guide since January 2024',
    'toursCompleted': 45,
    'experience': '5 years',
    'specializations': ['Adventure', 'Culture', 'Nature'],
    'languages': ['English', 'Tagalog', 'Cebuano'],
    'certifications': [
      'Licensed Tour Guide',
      'First Aid Certified',
      'PADI Diver'
    ],
    'lguDocuments': ['Business Permit', 'Barangay Clearance', 'NBI Clearance'],
  };

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
      if (_userProfile != null) {
        _activeStatus = _userProfile!.activeStatus == 1;
      }
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
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
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
                  Text(_userProfile?.displayName ?? 'Tour Guide',
                      style: AppTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(_userProfile?.email ?? '', style: AppTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    _userProfile?.createdAt != null
                        ? 'Member since ${_userProfile!.createdAt!.year}'
                        : 'Member since 2024',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        '${_userProfile?.toursCompleted ?? 0}',
                        'Tours Completed',
                        Icons.check_circle,
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: AppTheme.dividerColor,
                      ),
                      _buildStatItem(
                        '${_userProfile?.averageRating?.toStringAsFixed(1) ?? '0.0'}',
                        'Average Rating',
                        Icons.star,
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: AppTheme.dividerColor,
                      ),
                      _buildStatItem(
                        _activeStatus ? 'Online' : 'Offline',
                        'Status',
                        Icons.circle,
                        color: _activeStatus
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

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
                      Text('Account Information',
                          style: AppTheme.headlineSmall),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) =>
                                    const GuideEditAccountScreen()),
                          );
                        },
                        icon: const Icon(
                          Icons.edit,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.person, 'Full Name',
                      _userProfile?.displayName ?? 'Tour Guide'),
                  _buildInfoRow(
                      Icons.email, 'Email', _userProfile?.email ?? ''),
                  _buildInfoRow(Icons.phone, 'Phone',
                      _userProfile?.phoneNumber ?? 'Not provided'),
                  _buildInfoRow(Icons.work, 'Experience',
                      'Guide since ${_userProfile?.createdAt?.year ?? 2024}'),
                  if (_userProfile?.languages != null &&
                      _userProfile!.languages!.isNotEmpty)
                    _buildLanguagesRow(
                        Icons.language, 'Languages', _userProfile!.languages!),
                  _buildSpecializationsRow(Icons.star, 'Specializations',
                      _userProfile?.specializations ?? []),
                  _buildAvailabilityRow(Icons.calendar_today, 'Availability',
                      _userProfile?.availability ?? []),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Certifications
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Certifications', style: AppTheme.headlineSmall),
                  const SizedBox(height: 16),
                  if (_userProfile?.certifications != null &&
                      _userProfile!.certifications!.isNotEmpty)
                    Column(
                      children: _userProfile!.certifications!
                          .map((cert) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.verified,
                                      color: AppTheme.successColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(cert, style: AppTheme.bodyMedium),
                                  ],
                                ),
                              ))
                          .toList(),
                    )
                  else
                    Text(
                      'No certifications available',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // LGU Documents
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LGU Documents', style: AppTheme.headlineSmall),
                  const SizedBox(height: 16),
                  if (_userProfile?.lguDocuments != null &&
                      _userProfile!.lguDocuments!.isNotEmpty)
                    Column(
                      children: _userProfile!.lguDocuments!
                          .map((doc) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.description,
                                      color: AppTheme.accentColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(doc, style: AppTheme.bodyMedium),
                                  ],
                                ),
                              ))
                          .toList(),
                    )
                  else
                    Text(
                      'No LGU documents available',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // App Settings
            Container(
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
                      value: _selectedLanguage,
                      underline: Container(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedLanguage = newValue;
                          });
                        }
                      },
                      items: [
                        'English',
                        'Cebuano',
                        'Tagalog',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
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
                    subtitle: const Text('Receive tour updates and reminders'),
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
                        _activeStatus ? Icons.circle : Icons.circle_outlined,
                        color: _activeStatus
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                      ),
                    ),
                    title: const Text('Active Status'),
                    subtitle: Text(_activeStatus
                        ? 'Online - Available for tours'
                        : 'Offline - Not available'),
                    value: _activeStatus,
                    onChanged: (bool value) async {
                      setState(() {
                        _activeStatus = value;
                      });
                      // Update active status in database
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        try {
                          await _profileService.updateActiveStatus(
                              user.uid, value ? 1 : 0);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Error updating active status: ${e.toString()}'),
                              ),
                            );
                          }
                          // Revert the UI change on error
                          setState(() {
                            _activeStatus = !value;
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Other Options
            Container(
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
                          builder: (context) => const PaymentHistoryScreen(),
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
                    Icons.privacy_tip,
                    'Privacy Policy',
                    'Read our privacy policy',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  _buildOptionTile(
                    Icons.description,
                    'Terms and Conditions',
                    'Read our terms and conditions before accepting a booking',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsOfServiceScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
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

  Widget _buildStatItem(String value, String label, IconData icon,
      {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppTheme.primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTheme.headlineSmall
              .copyWith(color: color ?? AppTheme.primaryColor),
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

  Widget _buildLanguagesRow(
      IconData icon, String label, List<String> languages) {
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
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: languages
                      .map((language) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              language,
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecializationsRow(
      IconData icon, String label, List<String> specializations) {
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
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: specializations
                      .map((spec) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              spec,
                              style: TextStyle(
                                color: AppTheme.accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityRow(
      IconData icon, String label, List<String> availability) {
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
                if (availability.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: availability
                        .map((day) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                day,
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                        .toList(),
                  )
                else
                  Text(
                    'No availability set',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
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
