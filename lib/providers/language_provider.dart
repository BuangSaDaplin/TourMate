import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _defaultLocale = 'en';
  static const String _defaultLanguageCode = 'en';
  static const String _tagalogLanguageCode = 'tl';

  Locale _currentLocale = const Locale(_defaultLanguageCode, '');
  Map<String, dynamic> _translations = {};
  bool _isLoading = false;

  // Getters
  Locale get currentLocale => _currentLocale;
  String get currentLanguageCode => _currentLocale.languageCode;
  bool get isLoading => _isLoading;

  // Get translated text for a key
  String getText(String key) {
    return _translations[key] ?? key;
  }

  // Get all translations
  Map<String, dynamic> get translations => _translations;

  // Load translations from JSON file
  Future<void> _loadTranslations(String languageCode) async {
    _isLoading = true;
    notifyListeners();

    try {
      String fileName =
          languageCode == _tagalogLanguageCode ? 'app_tl.json' : 'app_en.json';

      String filePath = 'assets/l10n/$fileName';

      // Load JSON file from assets
      String jsonString = await rootBundle.loadString(filePath);
      Map<String, dynamic> jsonMap = json.decode(jsonString);

      _translations = jsonMap;
    } catch (e) {
      debugPrint('Error loading translations: $e');
      // Fallback to empty map if loading fails
      _translations = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Change language method
  Future<void> changeLanguage(String languageCode) async {
    if (languageCode == _currentLocale.languageCode) {
      return; // Already using this language
    }

    final Locale newLocale;
    switch (languageCode) {
      case _tagalogLanguageCode:
        newLocale = const Locale(_tagalogLanguageCode, '');
        break;
      case _defaultLanguageCode:
      default:
        newLocale = const Locale(_defaultLanguageCode, '');
        break;
    }

    _currentLocale = newLocale;

    // Load translations for the new language
    await _loadTranslations(languageCode);

    notifyListeners();

    // Persist preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
  }

  // Initialize from storage and load translations
  Future<void> loadAppLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString('language_code');
    if (languageCode != null) {
      _currentLocale = Locale(languageCode);
      notifyListeners();
    }
    await _loadTranslations(_currentLocale.languageCode);
  }

  // Initialize from storage (kept for backwards compatibility)
  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString('language_code');
    if (languageCode != null) {
      _currentLocale = Locale(languageCode);
      notifyListeners();
    }
  }

  // Check if a translation key exists
  bool hasKey(String key) {
    return _translations.containsKey(key);
  }

  // Get supported languages list
  static List<Map<String, String>> get supportedLanguages => [
        {
          'code': _defaultLanguageCode,
          'name': 'English',
          'nativeName': 'English'
        },
        {
          'code': _tagalogLanguageCode,
          'name': 'Tagalog',
          'nativeName': 'Tagalog'
        },
      ];

  // Get language display info
  Map<String, String> getCurrentLanguageInfo() {
    return supportedLanguages.firstWhere(
      (lang) => lang['code'] == currentLanguageCode,
      orElse: () => supportedLanguages.first,
    );
  }
}
