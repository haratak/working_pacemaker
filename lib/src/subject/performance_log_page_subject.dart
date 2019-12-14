import 'dart:async';
import 'dart:collection';

import "package:collection/collection.dart";
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:working_pacemaker/src/localization/messages.dart';
import 'package:working_pacemaker/src/model/performance_logging.dart';
import 'package:working_pacemaker/src/model/performance_logging/date_time_helper.dart';
import 'package:working_pacemaker/src/platform/platform.dart';

@immutable
class PerformanceLogPageSubject {
  final _listRestController =
      BehaviorSubject<UnmodifiableListView<ChartDataSet>>();
  final _showViewAllLogsButtonController = BehaviorSubject<bool>.seeded(false);
  final _showAllLogsButtonPressedController = StreamController<void>();
  final _resentLogsController = BehaviorSubject<RecentChartDateSets>();

  final List<StreamController> _controllers = [];

  final _ChartDataSetPresenter _presenter;
  final LogReader _logReader;
  final Analytics _analytics;

  PerformanceLogPageSubject(
      {@required LogReader performanceLogReader,
      @required AppMessages messages,
      @required Analytics analytics})
      : _presenter = _ChartDataSetPresenter(messages),
        _logReader = performanceLogReader,
        _analytics = analytics {
    _controllers.addAll([
      _listRestController,
      _showViewAllLogsButtonController,
      _showAllLogsButtonPressedController,
      _resentLogsController,
    ]);
    _showAllLogsButtonPressedController.stream
        .doOnData(
            (_) => _analytics.logEvent(name: 'view_all_logs_button_pressed'))
        .listen((_) => _listRest());
    _listResentLogs();
    _logReader.restExists().then(_showViewAllLogsButtonController.add);
  }

  Sink<void> get showAllLogsButtonPressed =>
      _showAllLogsButtonPressedController.sink;
  Stream<ChartDataSet> get today => _recentLogs.map((e) => e.today);
  Stream<ChartDataSet> get lastSevenDays =>
      _recentLogs.map((e) => e.lastSevenDays);
  Stream<ChartDataSet> get thisMonth => _recentLogs.map((e) => e.thisMonth);
  Stream<bool> get showViewAllLogsButton =>
      _showViewAllLogsButtonController.stream;
  Stream<UnmodifiableListView<ChartDataSet>> get listOfRest =>
      _listRestController.stream;

  void dispose() {
    _controllers.forEach((c) => c.close());
  }

  Stream<RecentChartDateSets> get _recentLogs => _resentLogsController.stream;

  void _listResentLogs() async {
    final recent = await _logReader.recent();

    final today = _presenter.todayChartView(recent.today);
    final lastSevenDays =
        _presenter.lastSevenDaysChartView(recent.lastSevenDays);
    final thisMonth = _presenter.thisMonthChartView(recent.thisMonth);

    _resentLogsController
        .add(RecentChartDateSets(today, lastSevenDays, thisMonth));
  }

  void _listRest() async {
    final result = await _logReader.listOfRest();
    _listRestController
        .add(UnmodifiableListView(result.map(_presenter.pastMonthChartView)));
    Future.delayed(const Duration(milliseconds: 500), () {
      _showViewAllLogsButtonController.add(false);
    });
  }
}

class ChartDataSet {
  final String period;
  final String totalWorkingTime;
  final UnmodifiableListView<ChartData> dataSet;
  ChartDataSet(this.period, this.totalWorkingTime, this.dataSet);
}

class ChartData {
  final DateTime time;
  // Minutes or hours.
  final int y;
  ChartData(this.time, this.y);
  ChartData.zero(this.time) : y = 0;
}

class RecentChartDateSets {
  final ChartDataSet today;
  final ChartDataSet lastSevenDays;
  final ChartDataSet thisMonth;
  RecentChartDateSets(this.today, this.lastSevenDays, this.thisMonth);
}

class _ChartDataSetPresenter {
  final AppMessages _messages;

  _ChartDataSetPresenter(this._messages);

  ChartDataSet todayChartView(PerformanceLogs todayLogs) {
    return ChartDataSet(_messages.today, _hoursMinutesFormat(_sum(todayLogs)),
        UnmodifiableListView(_toTodayChartDataSet(todayLogs)));
  }

  ChartDataSet lastSevenDaysChartView(PerformanceLogs lastSevenDaysLogs) {
    return ChartDataSet(
        _messages.lastSevenDays,
        _hoursMinutesFormat(_sum(lastSevenDaysLogs)),
        UnmodifiableListView(_toLastSevenDaysChartDataSet(lastSevenDaysLogs)));
  }

  ChartDataSet thisMonthChartView(PerformanceLogs monthLogs) {
    return ChartDataSet(
        _messages.thisMonth,
        _hoursMinutesFormat(_sum(monthLogs)),
        UnmodifiableListView(_toMonthChartDataSet(monthLogs)));
  }

  ChartDataSet pastMonthChartView(PerformanceLogs monthLogs) {
    return ChartDataSet(
        _messages.month(monthLogs.dateTime),
        _hoursMinutesFormat(_sum(monthLogs)),
        UnmodifiableListView(_toMonthChartDataSet(monthLogs)));
  }

  UnmodifiableListView<ChartData> _toTodayChartDataSet(
      PerformanceLogs todayLogs) {
    // TODO: how to render chart x axis nicely with no data set?
    return UnmodifiableListView([
      ChartData.zero(midnightOf(todayLogs.dateTime)),
      ...todayLogs.map((e) => ChartData(e.finishedTime, e.minutes)),
      ChartData.zero(tomorrowMidnightOf(todayLogs.dateTime))
    ]);
  }

  UnmodifiableListView<ChartData> _toLastSevenDaysChartDataSet(
      PerformanceLogs lastSevenDaysLogs) {
    final dataSet = _toDayPerformances(lastSevenDaysLogs)
        .map((e) => ChartData(e.day, e.totalWorkingDuration.inHours))
        .toList();

    final beginningDay = midnightOf(lastSevenDaysLogs.dateTime)
        .subtract(const Duration(days: 6));
    // Data set with ChartData.zero interpolated at every no data day.
    final resultDataSet = List.generate(7, (index) {
      final day = beginningDay.add(Duration(days: index));
      return dataSet.firstWhere((data) => data.time == day,
          orElse: () => ChartData.zero(day));
    });

    return UnmodifiableListView(resultDataSet);
  }

  UnmodifiableListView<ChartData> _toMonthChartDataSet(
      PerformanceLogs monthLogs) {
    final dataSet = _toDayPerformances(monthLogs)
        .map((e) => ChartData(e.day, e.totalWorkingDuration.inHours))
        .toList();

    final beginningDay = beginningDayOfThisMonth(monthLogs.dateTime);
    // Data set with ChartData.zero interpolated at every no data day.
    final resultDataSet =
        List.generate(endingDayOfThisMonth(monthLogs.dateTime).day, (index) {
      final day = beginningDay.add(Duration(days: index));
      return dataSet.firstWhere((data) => data.time == day,
          orElse: () => ChartData.zero(day));
    });
    return UnmodifiableListView(resultDataSet);
  }

  Iterable<_DayPerformance> _toDayPerformances(PerformanceLogs logs) {
    return groupBy(logs, (data) => midnightOf(data.finishedTime))
        .map((day, performanceLogs) => MapEntry(
            day,
            Duration(
                minutes: performanceLogs
                    .map((log) => log.minutes)
                    .fold(0, (p, e) => p + e))))
        .entries
        .map((dayAndPerformance) =>
            _DayPerformance(dayAndPerformance.key, dayAndPerformance.value));
  }

  Duration _sum(Iterable<PerformanceLog> logs) => Duration(
      minutes: logs
          .map((e) => e.minutes)
          .fold(0, (prev, element) => prev + element));

  String _hoursMinutesFormat(Duration duration) {
    final hours = duration.inHours;
    final minutes = (duration - Duration(hours: hours)).inMinutes;
    final minutesString = minutes >= 10 ? minutes.toString() : '0$minutes';
    return '$hours:$minutesString';
  }
}

class _DayPerformance {
  final DateTime day;
  final Duration totalWorkingDuration;
  _DayPerformance(this.day, this.totalWorkingDuration);
}
