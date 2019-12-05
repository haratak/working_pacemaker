import 'package:meta/meta.dart';
import 'package:working_pacemaker/src/model/performance_logging/date_time_helper.dart';
import 'package:working_pacemaker/src/model/performance_logging/repository.dart';
import 'package:working_pacemaker/src/platform/platform.dart';

import 'analytics_logger.dart';

class LogDeleter {
  final _Repository _repository;
  final AnalyticsLogger _logger;

  LogDeleter({@required Storage storage, @required Analytics analytics})
      : assert(analytics != null),
        _repository = _Repository(storage),
        _logger = AnalyticsLogger(analytics);

  Future<void> deleteOldLogs({@visibleForTesting DateTime now}) async {
    const monthsAgo = 11;
    final month = beginningDayOfThisMonth(now == null ? DateTime.now() : now);
    final oldestMonthToKeep =
        DateTime(month.year, month.month - monthsAgo, month.day);

    final months = await _repository.listKeys();

    final target = months.where((key) => key.isBefore(oldestMonthToKeep));
    final result = <DateTime>[];

    for (final month in target) {
      if (await _repository.deleteLogsOfMonth(month)) {
        result.add(month);
      }
    }

    if (result.isNotEmpty) {
      _logger.logOldMonthPerformanceLogsAreDeleted(
          result.map(_repository.getKeyOfMonth).toList());
    }
  }
}

class _Repository extends PerformanceLogRepository {
  final Storage storage;

  _Repository(this.storage);

  Future<List<DateTime>> listKeys() => storage
      .listKeys(namespace: namespace)
      .then((list) => list.map(keyToMonth).toList());

  Future<bool> deleteLogsOfMonth(DateTime month) =>
      storage.delete(keyOfMonth(month), namespace: namespace);

  String getKeyOfMonth(DateTime month) => keyOfMonth(month);
}
