import 'package:pedantic/pedantic.dart';
import 'package:working_pacemaker/src/platform/platform.dart';

class AnalyticsLogger {
  final Analytics _analytics;

  AnalyticsLogger(this._analytics);

  void logWorkingDurationChanged(Duration newDuration) async {
    assert(newDuration != null);
    unawaited(_analytics
        .logEvent(name: 'setting_of_working_duration_changed', parameters: {
      'minutes': newDuration.inMinutes,
    }));
  }

  void logBreakingDurationChanged(Duration newDuration) async {
    assert(newDuration != null);
    unawaited(_analytics
        .logEvent(name: 'setting_of_breaking_duration_changed', parameters: {
      'minutes': newDuration.inMinutes,
    }));
  }
}
