import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../widgets/language_switcher.dart';
import '../utils/app_localizations.dart';

/**
 * Example of how to integrate the language switching system into existing screens
 * This demonstrates the Profile Screen integration with the Language Switcher
 */

class ProfileScreenExample extends StatelessWidget {
  const ProfileScreenExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t(AppTranslationKeys.profile)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(context),
            const SizedBox(height: 24),

            // Language Settings Section
            _buildLanguageSection(context),
            const SizedBox(height: 24),

            // Profile Options Section
            _buildProfileOptionsSection(context),
            const SizedBox(height: 24),

            // App Information Section
            _buildAppInfoSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Theme.of(context).primaryColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      languageProvider.getText('profile')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${context.t(AppTranslationKeys.welcome)}, User!',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          languageProvider.getText('appName'),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t(AppTranslationKeys.settings),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Using the Language Switcher Widget
            const LanguageSwitcher(),
            const SizedBox(height: 16),

            // Alternative: Using the compact version
            const Divider(),
            const SizedBox(height: 16),
            const CompactLanguageSwitcher(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOptionsSection(BuildContext context) {
    final options = [
      {
        'icon': Icons.person,
        'title': context.t(AppTranslationKeys.profile),
        'subtitle': 'Edit your profile information',
        'onTap': () => _showUnderConstruction(context, 'Profile Edit'),
      },
      {
        'icon': Icons.book_online,
        'title': context.t(AppTranslationKeys.bookings),
        'subtitle': 'View your tour bookings',
        'onTap': () => _showUnderConstruction(context, 'My Bookings'),
      },
      {
        'icon': Icons.favorite,
        'title': context.t(AppTranslationKeys.favorites),
        'subtitle': 'Your favorite tours',
        'onTap': () => _showUnderConstruction(context, 'Favorites'),
      },
      {
        'icon': Icons.message,
        'title': context.t(AppTranslationKeys.messages),
        'subtitle': 'Chat with tour guides',
        'onTap': () => _showUnderConstruction(context, 'Messages'),
      },
      {
        'icon': Icons.notifications,
        'title': context.t(AppTranslationKeys.notifications),
        'subtitle': 'Manage notifications',
        'onTap': () => _showUnderConstruction(context, 'Notifications'),
      },
      {
        'icon': Icons.logout,
        'title': context.t(AppTranslationKeys.logout),
        'subtitle': 'Sign out of your account',
        'onTap': () => _showLogoutDialog(context),
        'textColor': Colors.red,
      },
    ];

    return Column(
      children: options.map((option) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              option['icon'] as IconData,
              color: option['textColor'] as Color? ??
                  Theme.of(context).primaryColor,
            ),
            title: Text(
              option['title'] as String,
              style: TextStyle(
                color: option['textColor'] as Color? ?? null,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(option['subtitle'] as String),
            trailing: const Icon(Icons.chevron_right),
            onTap: option['onTap'] as VoidCallback?,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAppInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(context, 'Version', '1.0.0'),
            _buildInfoRow(context, 'Language',
                context.currentLanguage['nativeName'] ?? 'English'),
            _buildInfoRow(context, 'Last Updated', '2024-01-04'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  void _showUnderConstruction(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Coming Soon'),
        content: Text('$feature feature is under construction.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.t(AppTranslationKeys.ok)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t(AppTranslationKeys.logout)),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.t(AppTranslationKeys.cancel)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implement logout logic here
            },
            child: Text(
              context.t(AppTranslationKeys.logout),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

/**
 * Example of how to use translations in any widget
 */
class TranslationExampleWidget extends StatelessWidget {
  const TranslationExampleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Basic translation usage
        Text(context.t(AppTranslationKeys.welcome)),

        // Using with string interpolation
        Text('${context.t(AppTranslationKeys.welcome)}, John!'),

        // Conditional UI based on language
        if (context.isEnglish) ...[
          Text('Welcome to our app!'),
        ] else if (context.isTagalog) ...[
          Text('Maligayang pagdating sa aming app!'),
        ],

        // Using with buttons
        ElevatedButton(
          onPressed: () async {
            await context.changeLanguage('tl'); // Switch to Tagalog
          },
          child: Text(context.t(AppTranslationKeys.changeLanguage)),
        ),
      ],
    );
  }
}
