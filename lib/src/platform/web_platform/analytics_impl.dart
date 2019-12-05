import 'package:meta/meta.dart';

import '../platform.dart' show Analytics;

/// AnalyticsImpl for Web.
///
/// Currently do nothing.
/// One can set this up by using 'package:usage/usage_html.dart',
/// or writing an inter-op code for Firebase Web JS API.
class AnalyticsImpl extends Analytics {
  final Null navigatorObserver = null;

  AnalyticsImpl(String appTitle) : super(appTitle);

  Future<void> logAppOpen() async {
    // Unimplemented.
  }

  Future<void> logEvent(
      {@required String name, Map<String, dynamic> parameters}) async {
    // Unimplemented.
  }

  Future<void> setCurrentScreen(
      {@required String screenName, String screenClassOverride}) async {
    // Unimplemented.
  }
}
