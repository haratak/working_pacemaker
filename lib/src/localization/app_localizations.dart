import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'generated/messages_all.dart';
import 'messages.dart';

final List<Locale> supportedLocales =
    _supportedLanguageCodes.map((l) => Locale(l, '')).toList();

const List<String> _supportedLanguageCodes = ['en', 'ja'];

/// Application-wide localization.
class AppLocalizations with AppMessagesMixin {
  static Future<AppLocalizations> load(Locale locale) async {
    final name = locale.countryCode == null || locale.countryCode.isEmpty
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);

    await initializeMessages(localeName);
    Intl.defaultLocale = localeName;

    return AppLocalizations();
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  bool isSupported(Locale locale) =>
      _supportedLanguageCodes.contains(locale.languageCode);

  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
