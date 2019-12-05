import 'package:pedantic/pedantic.dart';
import 'package:working_pacemaker/src/model/performance_logging/log_reader.dart';
import 'package:working_pacemaker/src/platform/platform.dart';

class AnalyticsLogger {
  final Analytics _analytics;
  AnalyticsLogger(this._analytics);

  void logPerformanceLogging(PerformanceLog log) {
    assert(log != null);
    unawaited(_analytics.logEvent(
        name: 'performance_logging', parameters: log.toJson()));
  }

  void logFailedPerformanceLogging(PerformanceLog log) {
    assert(log != null);
    unawaited(_analytics.logEvent(
        name: 'failed_performance_logging', parameters: log.toJson()));
  }

  void logOldMonthPerformanceLogsAreDeleted(List<String> deletedMonthKeys) {
    assert(deletedMonthKeys != null && deletedMonthKeys.isNotEmpty);

    unawaited(_analytics
        .logEvent(name: 'old_month_performance_logs_are_deleted', parameters: {
      'deleted_months': deletedMonthKeys.join(', '),
    }));
  }
}
