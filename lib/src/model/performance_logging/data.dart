import 'dart:collection';

class PerformanceLog {
  final DateTime finishedTime;
  final int minutes;
  static const _finishedTimeKey = 'f';
  static const _minutesKey = 'm';

  PerformanceLog(this.finishedTime, this.minutes);

  // Manual json converting for this simple usage.
  PerformanceLog.fromJson(Map<String, dynamic> json)
      : finishedTime =
            DateTime.fromMillisecondsSinceEpoch(json[_finishedTimeKey]),
        minutes = json[_minutesKey];

  Map<String, dynamic> toJson() => {
        _finishedTimeKey: finishedTime.millisecondsSinceEpoch,
        _minutesKey: minutes,
      };
}

// Note: this is more readable than "Tuple2<DateTime, List<PerformanceLog>>".
class PerformanceLogs with IterableMixin<PerformanceLog> {
  /// DateTime used for fetching this logs.
  final DateTime dateTime;
  // logs are ordered by finishedTime, asc.
  final List<PerformanceLog> _list;

  PerformanceLogs(this.dateTime, this._list);

  Iterator<PerformanceLog> get iterator => _list.iterator;
}

class RecentLogs {
  final PerformanceLogs today;
  final PerformanceLogs lastSevenDays;
  final PerformanceLogs thisMonth;

  RecentLogs(this.today, this.lastSevenDays, this.thisMonth);
}
