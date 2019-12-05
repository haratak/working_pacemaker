import 'dart:math';

import 'package:meta/meta.dart';
import 'package:quiver/iterables.dart';
import 'package:tuple/tuple.dart';
import 'package:working_pacemaker/src/flavor_config/production_config.dart';
import 'package:working_pacemaker/src/model/performance_logging.dart';
import 'package:working_pacemaker/src/model/performance_logging/date_time_helper.dart';

class PerformanceLogDataSetGenerator {
  List<List<PerformanceLog>> typicalDataSet(DateTime now,
      {@required bool untilNow}) {
    final result = <List<PerformanceLog>>[];
    final random = Random();
    var month = now;
    if (random.nextInt(100) < 70) {
      // This month.
      result.add(typicalDataSetOfMonth(month, untilNow: untilNow));
    }

    // Last 13 months.
    // The oldest 2 month are to be subject of deleting at app launching.
    range(13, 0, -1).forEach((_) {
      month = beginningDayOfLastMonth(month);
      if (random.nextInt(100) < 70) {
        result.add(typicalDataSetOfMonth(month, untilNow: false));
      }
    });

    return result;
  }

  List<List<PerformanceLog>> maximumDataSet(DateTime now,
      {@required bool untilNow}) {
    final result = <List<PerformanceLog>>[];

    var month = now;

    // This month.
    result.add(maximumDataSetOfMonth(month, untilNow: untilNow));

    // Last 13 months.
    // The oldest 2 month are to be subject of deleting at app launching.
    range(13, 0, -1).forEach((_) {
      month = beginningDayOfLastMonth(month);
      result.add(maximumDataSetOfMonth(month, untilNow: false));
    });

    return result;
  }

  List<PerformanceLog> maximumDataSetOfMonth(DateTime now,
      {bool untilNow = false}) {
    final workingDuration =
        productionConfig.pacemakerDefaultSettings.workingDurationOptions.first;
    final breakingDuration =
        productionConfig.pacemakerDefaultSettings.breakingDurationOptions.first;

    final performanceLogs = List<PerformanceLog>();

    var workFinishedDateTime =
        beginningDayOfThisMonth(now).add(workingDuration);
    final stoppingDateTime =
        untilNow ? now : tomorrowMidnightOf(endingDayOfThisMonth(now));
    while (workFinishedDateTime.isBefore(stoppingDateTime)) {
      performanceLogs
          .add(PerformanceLog(workFinishedDateTime, workingDuration.inMinutes));
      workFinishedDateTime =
          workFinishedDateTime.add(breakingDuration).add(workingDuration);
    }

    return performanceLogs;
  }

  List<PerformanceLog> typicalDataSetOfMonth(DateTime now,
      {bool untilNow = false}) {
    final performanceLogs = List<PerformanceLog>();

    final stoppingDateTime =
        untilNow ? now : tomorrowMidnightOf(endingDayOfThisMonth(now));

    final generator = _TypicalRandomDataSetGenerator();

    DateTime lastDateTime = beginningDayOfThisMonth(now);
    do {
      final dataSet = generator.generateAt(lastDateTime);
      if (dataSet != null) {
        final workFinishedDateTime = lastDateTime.add(dataSet.item1);
        performanceLogs
            .add(PerformanceLog(workFinishedDateTime, dataSet.item1.inMinutes));
        lastDateTime = workFinishedDateTime.add(dataSet.item2);
      } else {
        lastDateTime = lastDateTime.add(const Duration(hours: 1));
      }
    } while (lastDateTime.isBefore(stoppingDateTime));

    return performanceLogs;
  }
}

typedef DataSetGenerator = Tuple2<Duration, Duration> Function();

class _TypicalRandomDataSetGenerator {
  static final _random = Random();

  _TypicalRandomDataSetGenerator();

  /// Tuple of working duration and breaking duration.
  ///
  /// Nullable if no data set, which means, one didn't worked at this date time.
  Tuple2<Duration, Duration> generateAt(DateTime dateTime) {
    if (_isWeekDay(dateTime) && _isDayTime(dateTime)) {
      if (_random.nextInt(100) < 85) {
        return _generate();
      }
    } else {
      if (_random.nextInt(100) < 10) {
        return _generate();
      }
    }
    return null;
  }

  Tuple2<Duration, Duration> _generate() {
    final woLength =
        productionConfig.pacemakerDefaultSettings.workingDurationOptions.length;
    final boLength = productionConfig
        .pacemakerDefaultSettings.breakingDurationOptions.length;

    if (_random.nextInt(100) <= 80) {
      return Tuple2(
        productionConfig.pacemakerDefaultSettings.workingDuration,
        productionConfig.pacemakerDefaultSettings.breakingDuration,
      );
    } else {
      return Tuple2(
        productionConfig.pacemakerDefaultSettings
            .workingDurationOptions[_random.nextInt(woLength)],
        productionConfig.pacemakerDefaultSettings
            .breakingDurationOptions[_random.nextInt(boLength)],
      );
    }
  }

  bool _isDayTime(DateTime dateTime) {
    final hour = dateTime.hour;
    return hour >= 9 && hour <= 20;
  }

  bool _isWeekDay(DateTime dateTime) {
    final weekday = dateTime.weekday;
    return weekday >= 1 && weekday <= 5;
  }
}
