import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Get [AppLocalizations], by short method name.
AppLocalizations l(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations);

/// Get [Locale]'s string representation.
///
/// This is useful for framework independent modules,
/// since [Locale] is a part of Flutter.
String locale(BuildContext context) =>
    Localizations.localeOf(context).languageCode;
