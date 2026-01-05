import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

// Extension to easily access translations from any BuildContext
extension AppLocalizations on BuildContext {
  // Get translated text for a key
  String t(String key) {
    return Provider.of<LanguageProvider>(this, listen: false).getText(key);
  }

  // Get translated text with listen: true for rebuilds
  String tWatch(String key) {
    return Provider.of<LanguageProvider>(this, listen: true).getText(key);
  }

  // Get current language info
  Map<String, String> get currentLanguage {
    return Provider.of<LanguageProvider>(this, listen: false)
        .getCurrentLanguageInfo();
  }

  // Check if current language is English
  bool get isEnglish {
    return Provider.of<LanguageProvider>(this, listen: false)
            .currentLanguageCode ==
        'en';
  }

  // Check if current language is Tagalog
  bool get isTagalog {
    return Provider.of<LanguageProvider>(this, listen: false)
            .currentLanguageCode ==
        'tl';
  }

  // Change language
  Future<void> changeLanguage(String languageCode) async {
    await Provider.of<LanguageProvider>(this, listen: false)
        .changeLanguage(languageCode);
  }
}

// Utility class for common translation patterns
class AppTranslationKeys {
  // Common app keys
  static const String appName = 'appName';
  static const String welcome = 'welcome';
  static const String bookNow = 'bookNow';
  static const String tours = 'tours';
  static const String profile = 'profile';
  static const String home = 'home';
  static const String search = 'search';
  static const String favorites = 'favorites';
  static const String bookings = 'bookings';
  static const String messages = 'messages';
  static const String notifications = 'notifications';
  static const String settings = 'settings';
  static const String logout = 'logout';
  static const String login = 'login';
  static const String signup = 'signup';

  // Form related keys
  static const String email = 'email';
  static const String password = 'password';
  static const String confirmPassword = 'confirmPassword';
  static const String name = 'name';
  static const String phone = 'phone';
  static const String save = 'save';
  static const String cancel = 'cancel';
  static const String edit = 'edit';
  static const String delete = 'delete';
  static const String view = 'view';
  static const String back = 'back';
  static const String next = 'next';
  static const String previous = 'previous';

  // Status keys
  static const String loading = 'loading';
  static const String error = 'error';
  static const String success = 'success';
  static const String retry = 'retry';
  static const String ok = 'ok';
  static const String yes = 'yes';
  static const String no = 'no';

  // Language keys
  static const String language = 'language';
  static const String english = 'english';
  static const String tagalog = 'tagalog';
  static const String changeLanguage = 'changeLanguage';
  static const String selectLanguage = 'selectLanguage';

  // Tour related keys
  static const String tourDetails = 'tourDetails';
  static const String tourGuide = 'tourGuide';
  static const String price = 'price';
  static const String duration = 'duration';
  static const String location = 'location';
  static const String description = 'description';
  static const String reviews = 'reviews';
  static const String rating = 'rating';
  static const String date = 'date';
  static const String time = 'time';
  static const String guests = 'guests';
  static const String total = 'total';
  static const String confirm = 'confirm';
  static const String payment = 'payment';
  static const String bookingConfirmed = 'bookingConfirmed';

  // Booking keys
  static const String myBookings = 'myBookings';
  static const String upcomingTours = 'upcomingTours';
  static const String pastTours = 'pastTours';
  static const String createTour = 'createTour';
  static const String manageTours = 'manageTours';
  static const String tourManagement = 'tourManagement';

  // Guide keys
  static const String guideProfile = 'guideProfile';
  static const String becomeGuide = 'becomeGuide';
  static const String verification = 'verification';
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';

  // Dashboard keys
  static const String dashboard = 'dashboard';
  static const String analytics = 'analytics';
  static const String users = 'users';
  static const String guides = 'guides';
  static const String toursCount = 'toursCount';
  static const String bookingsCount = 'bookingsCount';
  static const String revenue = 'revenue';
  static const String popularTours = 'popularTours';
  static const String recentBookings = 'recentBookings';

  // Admin keys
  static const String systemSettings = 'systemSettings';
  static const String adminPanel = 'adminPanel';
  static const String accessControl = 'accessControl';
  static const String userManagement = 'userManagement';
  static const String guideVerification = 'guideVerification';
  static const String tourModeration = 'tourModeration';
  static const String paymentManagement = 'paymentManagement';
  static const String reviewManagement = 'reviewManagement';
  static const String notificationSettings = 'notificationSettings';
  static const String messagingMonitor = 'messagingMonitor';
  static const String bookingMonitoring = 'bookingMonitoring';
  static const String overview = 'overview';
}

// Widget to wrap any screen with automatic translation support
class LocalizedWidget extends StatelessWidget {
  final Widget child;

  const LocalizedWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // This widget just provides the context extension
    return child;
  }
}
