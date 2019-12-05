import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:meta/meta.dart';
import 'package:working_pacemaker/src/flavor_config/flavor_config.dart';

import '../platform.dart' show Analytics;

Future<Analytics> initializeAnalytics(
    {@required Flavor flavor, @required String appTitle}) async {
  switch (flavor) {
    case Flavor.production:
      return _AnalyticsImpl(FirebaseAnalytics(), appTitle);
      break;
    case Flavor.dev:
    case Flavor.integrationTesting:
      return _FakeAnalyticsImpl(appTitle);
      break;
    default:
      throw ArgumentError();
  }
}

class _AnalyticsImpl extends Analytics {
  final FirebaseAnalytics _firebaseAnalytics;
  final FirebaseAnalyticsObserver navigatorObserver;

  _AnalyticsImpl(this._firebaseAnalytics, String appTitle)
      : assert(appTitle != null),
        navigatorObserver =
            FirebaseAnalyticsObserver(analytics: _firebaseAnalytics),
        super(appTitle);

  Future<void> logAppOpen() => _firebaseAnalytics.logAppOpen();

  Future<void> logEvent(
      {@required String name, Map<String, dynamic> parameters}) {
    return _firebaseAnalytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  Future<void> setCurrentScreen(
      {@required String screenName, String screenClassOverride}) {
    screenClassOverride ??= appTitle;

    return _firebaseAnalytics.setCurrentScreen(
      screenName: screenName,
      screenClassOverride: screenClassOverride,
    );
  }
}

/// Fake Analytics.
///
/// Each method just do debug print.
/// This is useful for dev and integrationTesting flavor,
/// since we don't usually want to log events on them.
class _FakeAnalyticsImpl extends Analytics {
  // Returns null instead of a fake navigatorObserver
  // for saving the time to implement.
  final Null navigatorObserver = null;

  _FakeAnalyticsImpl(String appTitle) : super(appTitle);

  Future<void> logAppOpen() async {
    print('Analytics logAppOpen');
  }

  Future<void> logEvent(
      {@required String name, Map<String, dynamic> parameters}) async {
    print('Analytics logEvent with name: $name, parameters: $parameters');
  }

  Future<void> setCurrentScreen(
      {@required String screenName, String screenClassOverride}) async {
    screenClassOverride ??= appTitle;
    print('Analytics setCurrentScreen with name: $screenName,'
        'screenClassOverride: $screenClassOverride');
  }
}
