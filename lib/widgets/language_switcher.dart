import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class LanguageSwitcher extends StatelessWidget {
  final bool showLabels;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const LanguageSwitcher({
    super.key,
    this.showLabels = true,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Container(
          width: width,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showLabels) ...[
                Text(
                  languageProvider.getText('language'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
              ],
              _buildLanguageSelector(context, languageProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageSelector(
      BuildContext context, LanguageProvider languageProvider) {
    final supportedLanguages = LanguageProvider.supportedLanguages;
    final currentLanguage = languageProvider.getCurrentLanguageInfo();

    return DropdownButtonFormField<String>(
      value: languageProvider.currentLanguageCode,
      decoration: InputDecoration(
        labelText: languageProvider.getText('selectLanguage'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIcon: const Icon(Icons.language),
      ),
      icon: const Icon(Icons.keyboard_arrow_down),
      style: Theme.of(context).textTheme.bodyMedium,
      items: supportedLanguages.map((language) {
        return DropdownMenuItem<String>(
          value: language['code']!,
          child: Row(
            children: [
              _getLanguageFlag(language['code']!),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    language['nativeName']!,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    language['name']!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: languageProvider.isLoading
          ? null
          : (String? newLanguageCode) {
              if (newLanguageCode != null) {
                _changeLanguage(context, languageProvider, newLanguageCode);
              }
            },
    );
  }

  Widget _getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'tl':
        return _buildFlagIcon('🇵🇭');
      case 'en':
      default:
        return _buildFlagIcon('🇺🇸');
    }
  }

  Widget _buildFlagIcon(String flagEmoji) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      child: Text(
        flagEmoji,
        style: const TextStyle(fontSize: 20),
      ),
    );
  }

  Future<void> _changeLanguage(BuildContext context,
      LanguageProvider languageProvider, String languageCode) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      await languageProvider.changeLanguage(languageCode);
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Language changed to ${languageProvider.getCurrentLanguageInfo()['nativeName']}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change language: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

// Alternative compact language switcher (toggle style)
class CompactLanguageSwitcher extends StatelessWidget {
  const CompactLanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final supportedLanguages = LanguageProvider.supportedLanguages;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.language),
                  const SizedBox(width: 8),
                  Text(
                    languageProvider.getText('language'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: supportedLanguages.map((language) {
                    final isSelected = language['code'] ==
                        languageProvider.currentLanguageCode;
                    return GestureDetector(
                      onTap: languageProvider.isLoading
                          ? null
                          : () => _changeLanguage(
                              context, languageProvider, language['code']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _getLanguageFlag(language['code']!),
                            const SizedBox(width: 4),
                            Text(
                              language['code']!.toUpperCase(),
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'tl':
        return const Text('🇵🇭', style: TextStyle(fontSize: 16));
      case 'en':
      default:
        return const Text('🇺🇸', style: TextStyle(fontSize: 16));
    }
  }

  Future<void> _changeLanguage(BuildContext context,
      LanguageProvider languageProvider, String languageCode) async {
    try {
      await languageProvider.changeLanguage(languageCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Language changed to ${languageProvider.getCurrentLanguageInfo()['nativeName']}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to change language: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
