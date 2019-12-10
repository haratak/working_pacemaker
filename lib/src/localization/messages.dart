/// Intl Messages
///
/// This library can be imported to libraries in test_driver
/// for integration testing.
/// Do NOT import package:flutter libraries here,
/// otherwise test_driver will exit with errors.
library messages;

import 'package:intl/intl.dart';

/// Flutter independent localizing messages module.
class AppMessages with AppMessagesMixin {
  AppMessages([String locale]) {
    if (locale != null) {
      Intl.defaultLocale = locale;
    }
  }
}

mixin AppMessagesMixin {
  // For home page.
  String get workingPhase => Intl.message('Working');
  String get breakingPhase => Intl.message('Breaking');
  String get reset => Intl.message('Reset');
  // -------------------

  // For settings page.
  String get settings => Intl.message('Settings');
  String get workingDuration => Intl.message('Working Duration');
  String get breakingDuration => Intl.message('Breaking Duration');
  String minutes(int minutes) =>
      Intl.message('$minutes minutes', name: 'minutes', args: [minutes]);
  String selectDurationOf(String durationMessage) =>
      Intl.message('Select $durationMessage',
          name: 'selectDurationOf', args: [durationMessage]);
  // -----------------------

  // For performance log page.
  String get yourPerformance => Intl.message('Your Performance');
  String get today => Intl.message('Today');
  String get lastSevenDays => Intl.message('Seven Days');
  String get thisMonth => Intl.message('This Month');
  String month(DateTime date) =>
      DateFormat(DateFormat.MONTH, Intl.defaultLocale).format(date);
  String get showAllLogs => Intl.message('Show All Logs');
  String get logKeepingInformation =>
      Intl.message('Logs will be kept for a period of one year.');
  // ------------------------------
}
