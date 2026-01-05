import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tourmate_app/l10n/app_localizations.dart';

class TranslateService {
  static const LocalizationsDelegate<dynamic> delegate =
      _AppLocalizationsDelegate();

  static Future<TranslateService> load(Locale locale) {
    final String name =
        locale.countryCode!.isEmpty ? locale.languageCode : locale.toString();
    final String localeName = Intl.canonicalizedLocale(name);
    return Future.value(TranslateService());
  }

  static TranslateService of(BuildContext context) {
    return Localizations.of<TranslateService>(context, TranslateService)!;
  }

  String get title {
    return Intl.message(
      'TourMate',
      name: 'title',
      desc: 'Title for the application',
    );
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<TranslateService> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'tl', 'ceb'].contains(locale.languageCode);
  }

  @override
  Future<TranslateService> load(Locale locale) {
    return TranslateService.load(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
