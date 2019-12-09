import 'package:meta/meta.dart';
import 'package:quiver/iterables.dart';
import 'package:working_pacemaker/src/platform/platform.dart';

import 'data.dart';
import 'date_time_helper.dart';
import 'repository.dart';

export 'data.dart';

class LogReader {
  final _Repository _repository;

  LogReader({@required Storage storage})
      : assert(storage != null),
        _repository = _Repository(storage);

  Future<RecentLogs> recent() async {
    // TODO: Measure performance with low performance device. Isolate could be necessary.
    final _now = now;
    // Not using Future.wait but awaiting for each,
    // for the cache hitting in the repository.
    return RecentLogs(await listOfADay(_now),
        await listOfLastSevenDaysFrom(_now), await listOfThisMonth(_now));
  }

  Future<List<PerformanceLogs>> listOfRest() async {
    final result = <PerformanceLogs>[];
    var month = beginningDayOfLastMonth(now);
    await Future.forEach(range(1, 12), (_) async {
      result.add(await _listOfMonth(month));
      month = beginningDayOfLastMonth(month);
    });
    return result;
  }

  Future<bool> restExists() async {
    final _now = now;
    final beginningDayOf12MonthsAgo = DateTime(_now.year - 1, _now.month, 1);
    var month = beginningDayOfLastMonth(_now);
    var exists = false;

    while (!exists && month.isAfter(beginningDayOf12MonthsAgo)) {
      exists = await _repository.exists(month);
      month = beginningDayOfLastMonth(month);
    }

    return exists;
  }

  @visibleForTesting
  DateTime get now => DateTime.now();

  @visibleForTesting
  Future<PerformanceLogs> listOfADay(DateTime day) async {
    return PerformanceLogs(day, await _repository.listOfADay(day));
  }

  @visibleForTesting
  Future<PerformanceLogs> listOfLastSevenDaysFrom(DateTime day) async {
    return PerformanceLogs(day, await _repository.listOfLastSevenDaysFrom(day));
  }

  @visibleForTesting
  Future<PerformanceLogs> listOfThisMonth(DateTime month) {
    return _listOfMonth(now, useCache: true);
  }

  Future<PerformanceLogs> _listOfMonth(DateTime month,
      {useCache = false}) async {
    return PerformanceLogs(
        month, await _repository.listOfMonth(month, useCache: useCache));
  }
}

class _Repository with PerformanceLogRepository {
  @protected
  final Storage storage;

  // Key is a month number, value is dataSet of the month.
  final Map<int, List<PerformanceLog>> _cache = {};

  _Repository(this.storage);

  Future<List<PerformanceLog>> listOfADay(DateTime now) async {
    return (await listOfMonth(now, useCache: true))
        .where((data) =>
            data.finishedTime.isAfter(midnightOf(now)) &&
            data.finishedTime.isBefore(tomorrowMidnightOf(now)))
        .toList();
  }

  Future<List<PerformanceLog>> listOfLastSevenDaysFrom(DateTime now) async {
    final midnightOfSevenDaysAgo =
        midnightOf(now).subtract(const Duration(days: 7));

    final dataSet = await listOfMonth(now, useCache: true);
    final result = dataSet
        .where((data) =>
            data.finishedTime.isAfter(midnightOfSevenDaysAgo) &&
            data.finishedTime.isBefore(now))
        .toList();

    if (midnightOfSevenDaysAgo.month != now.month) {
      final dataSet = await listOfMonth(midnightOfSevenDaysAgo);
      final lastMonthDataSet = dataSet
          .where((data) => data.finishedTime.isAfter(midnightOfSevenDaysAgo));
      result.insertAll(0, lastMonthDataSet);
    }

    return result;
  }

  Future<bool> exists(DateTime month) {
    return storage.exists(keyOfMonth(month), namespace: namespace);
  }

  @override
  Future<List<PerformanceLog>> listOfMonth(DateTime month,
      {bool useCache = false}) async {
    if (!useCache) {
      return super.listOfMonth(month);
    }

    if (_cache[month.month] != null) {
      return Future.value(_cache[month.month]);
    } else {
      return _cache[month.month] = await super.listOfMonth(month);
    }
  }
}
