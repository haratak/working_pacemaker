import 'package:mockito/mockito.dart';
import 'package:quiver/collection.dart';
import 'package:quiver/iterables.dart';
import 'package:test/test.dart';
import 'package:working_pacemaker/dev_scripts/dev_platform.dart';
import 'package:working_pacemaker/dev_scripts/dev_scripts.dart';
import 'package:working_pacemaker/dev_scripts/performance_log_data_set_generator.dart';
import 'package:working_pacemaker/src/model/performance_logging.dart';
import 'package:working_pacemaker/src/model/performance_logging/date_time_helper.dart';
import 'package:working_pacemaker/src/platform/platform.dart';

import '../mock.dart';

class _FakePerformanceLogStorage extends Fake implements DevStorage {
  final Map<String, dynamic> _keyValue = {};
  // Namespace is ignored.
  Future<String> get(String key, {String namespace}) {
    return Future.value(_keyValue[key]);
  }

  // Namespace is ignored.
  Future<bool> exists(String key, {String namespace}) async {
    return (await get(key)) != null;
  }

  // Namespace is ignored.
  Future<bool> set(String key, String value, {String namespace}) {
    _keyValue[key] = value;
    return Future.value(true);
  }
}

mixin _FakeNow {
  DateTime now;
}

class _LoggerWithFakeNow = Logger with _FakeNow;
class _LogReaderWithFakeNow = LogReader with _FakeNow;

String _performanceLogStorageKey(DateTime dateTime) =>
    '${dateTime.year}_${dateTime.month}';

main() {
  Storage storage;

  setUp(() {
    storage = _FakePerformanceLogStorage();
  });

  group(Logger, () {
    _LoggerWithFakeNow logger;

    setUp(() {
      logger = _LoggerWithFakeNow(storage: storage, analytics: MockAnalytics());
    });

    test('Now is now.', () {
      final logger = Logger(storage: storage, analytics: MockAnalytics());
      final now = logger.now;
      expect(now.difference(DateTime.now()),
          lessThanOrEqualTo(const Duration(milliseconds: 1)));
    });

    group('Logging onWorkingPhaseIsFinished.', () {
      test('Set log (when storage value is null).', () async {
        logger.now = DateTime(2020, 1, 1);
        logger.onWorkingPhaseIsFinished.add(const Duration(minutes: 25));

        await Future.delayed(Duration.zero, () {
          expect(storage.get(_performanceLogStorageKey(logger.now)),
              completion('[{"f":1577804400000,"m":25}]'));
        });
      });

      test('Insert log (when storage value is not null).', () async {
        logger.now = DateTime(2020, 1, 1);
        logger.onWorkingPhaseIsFinished.add(const Duration(minutes: 25));
        // Wait for it will be logged.
        await Future.delayed(Duration.zero, () {});

        logger.now = DateTime(2020, 1, 1, 6);
        logger.onWorkingPhaseIsFinished.add(const Duration(minutes: 50));

        await Future.delayed(Duration.zero, () {
          expect(
              storage.get(_performanceLogStorageKey(logger.now)),
              completion(
                  '[{"f":1577804400000,"m":25},{"f":1577826000000,"m":50}]'));
        });
      });
    });
  });

  group(LogReader, () {
    _LogReaderWithFakeNow logReader;
    DevPerformanceLogRepository repository;
    final generator = PerformanceLogDataSetGenerator();

    setUp(() {
      logReader = _LogReaderWithFakeNow(storage: storage);
      repository = DevPerformanceLogRepository(storage);
    });

    test('Now is now.', () {
      final logReader = LogReader(storage: storage);
      final now = logReader.now;
      expect(now.difference(DateTime.now()),
          lessThanOrEqualTo(const Duration(milliseconds: 1)));
    });

    group('listOfToday.', () {
      group('With no data set.', () {
        test('Empty Logs.', () async {
          logReader.now = DateTime.now();
          final result = await logReader.getDailyPerformanceLog(logReader.now);
          expect(result, isEmpty);
        });
      });
      group('With data set.', () {
        setUp(() async {
          logReader.now = tomorrowMidnightOf(DateTime(2019, 12, 4))
              .subtract(const Duration(microseconds: 1));

          final dataSet =
              generator.maximumDataSetOfMonth(logReader.now, untilNow: true);
          await repository.set(logReader.now, dataSet);
        });
        test('Logs are all today\'s one.', () async {
          final result = await logReader.getDailyPerformanceLog(logReader.now);
          expect(
              result.every((log) => log.finishedTime.day == logReader.now.day),
              isTrue);
        });
        test('Logs are sorted by finishedTime ascendant order.', () async {
          final result = await logReader.getDailyPerformanceLog(logReader.now);
          final List<PerformanceLog> logs =
              result.map<PerformanceLog>((e) => e).toList();
          final minMax = extent<PerformanceLog>(
              logs,
              (PerformanceLog a, PerformanceLog b) =>
                  a.finishedTime.compareTo(b.finishedTime));
          expect(minMax.min, result.first);
          expect(minMax.max, result.last);
          final index = (result.length / 2).ceil();
          expect(
              result
                  .toList()[index]
                  .finishedTime
                  .isBefore(logs[index + 1].finishedTime),
              isTrue);
        });
      });
    });
    group('listOfLastSevenDays.', () {
      group('With no data set', () {
        test('Empty Logs.', () async {
          logReader.now = DateTime.now();
          final result = await logReader.listOfLastSevenDays(logReader.now);
          expect(result, isEmpty);
        });
      });
      group('With data set, across months and years.', () {
        DateTime lastMonth;

        setUp(() async {
          final today = DateTime(2020, 1, 4);
          lastMonth = beginningDayOfLastMonth(today);
          final tomorrow = tomorrowMidnightOf(today);
          logReader.now = tomorrow.subtract(const Duration(microseconds: 1));

          final todayDateSet =
              generator.maximumDataSetOfMonth(logReader.now, untilNow: true);
          final lastMonthDataSet =
              generator.maximumDataSetOfMonth(lastMonth, untilNow: false);
          await repository.set(logReader.now, todayDateSet);
          await repository.set(lastMonth, lastMonthDataSet);
        });

        test('Logs are all in last seven days (including boundary testing).',
            () async {
          final result = await logReader.listOfLastSevenDays(logReader.now);
          final midnightOfSevenDaysAgo =
              midnightOf(logReader.now).subtract(const Duration(days: 7));

          for (final log in result) {
            expect(log.finishedTime.compareTo(midnightOfSevenDaysAgo),
                isNonNegative);
            expect(log.finishedTime.compareTo(logReader.now), isNegative);
          }

          expect(result.first.finishedTime.day == midnightOfSevenDaysAgo.day,
              isTrue);
          expect(result.last.finishedTime.day == logReader.now.day, isTrue);

          expect(
              () => result.firstWhere((log) =>
                  log.finishedTime.day ==
                  endingDayOfThisMonth(midnightOfSevenDaysAgo).day),
              returnsNormally);

          expect(() => result.firstWhere((log) => log.finishedTime.day == 1),
              returnsNormally);
        });

        test('Logs are sorted by day ascendant order.', () async {
          final result = await logReader.listOfLastSevenDays(logReader.now);

          final minMax = extent<PerformanceLog>(
              result, (a, b) => a.finishedTime.compareTo(b.finishedTime));
          expect(minMax.min, result.first);
          expect(minMax.max, result.last);

          final lastMonthDataSet = result.takeWhile((log) =>
              log.finishedTime.day == endingDayOfThisMonth(lastMonth).day);
          expect(
              listsEqual(
                  lastMonthDataSet.map((e) => e.finishedTime).toList()..sort(),
                  lastMonthDataSet.map((e) => e.finishedTime).toList()),
              isTrue);

          final thisMonthDataSet = result.skipWhile((log) =>
              log.finishedTime.day == endingDayOfThisMonth(lastMonth).day);
          expect(
              listsEqual(
                  thisMonthDataSet.map((e) => e.finishedTime).toList()..sort(),
                  thisMonthDataSet.map((e) => e.finishedTime).toList()),
              isTrue);
        });
      });
    });

    group('listOfThisMonth.', () {
      group('With no data set.', () {
        test('Empty Logs.', () async {
          logReader.now = DateTime.now();
          final result = await logReader.listOfThisMonth(logReader.now);
          expect(result.dateTime.year, logReader.now.year);
          expect(result.dateTime.month, logReader.now.month);
          expect(result, isEmpty);
        });
      });
      group('With data set.', () {
        setUp(() {});
        test('Logs are all in this month (including boundary testing).',
            () async {
          // TODO: TBE.
        }, skip: true);

        test('Logs are sorted by day ascendant order.', () async {
          // TODO: TBE.
        }, skip: true);
      });
    });

    group('listOfRest.', () {
      List<DateTime> monthsWithData;

      setUp(() async {
        final today = DateTime(2020, 2, 4);
        logReader.now = today;

        final jan = beginningDayOfLastMonth(today);
        // Across year.
        final dec = beginningDayOfLastMonth(jan);
        final oct = DateTime(dec.year, dec.month - 2, 1);
        final jun = DateTime(oct.year, oct.month - 4, 1);
        // Oldest month.
        final mar = DateTime(jun.year, jun.month - 3, 1);

        monthsWithData = [jan, dec, oct, jun, mar];
        await for (final month in Stream.fromIterable(monthsWithData)) {
          await repository.set(month, generator.maximumDataSetOfMonth(month));
        }
      });
      test('11 lists of monthly Log, each is empty if no data set.', () async {
        final result = await logReader.listOfRest();
        expect(result.length, 11);

        final months = monthsWithData.map((e) => e.month);
        expect(
            result
                .where((e) => months.contains(e.dateTime.month))
                .every((e) => e.isNotEmpty),
            isTrue);
        expect(
            result
                .where((e) => !months.contains(e.dateTime.month))
                .every((e) => e.isEmpty),
            isTrue);
      });
    });
    group('restExists.', () {
      // TODO: TBE.
    });
  });

  test('DateTime helper.', () {
    final dateTime = DateTime(2020, 1, 30);

    expect(beginningDayOfThisMonth(dateTime), DateTime(2020, 1, 1));

    expect(endingDayOfThisMonth(dateTime), DateTime(2020, 1, 31));
    expect(endingDayOfThisMonth(DateTime(2019, 2, 1)), DateTime(2019, 2, 28));

    expect(
        beginningDayOfNextMonth(DateTime(2019, 12, 1)), DateTime(2020, 1, 1));

    expect(beginningDayOfLastMonth(dateTime), DateTime(2019, 12, 1));
    expect(tomorrowMidnightOf(DateTime(2019, 12, 31, 23, 59, 59)),
        DateTime(2020, 1, 1, 0, 0, 0));
    expect(midnightOf(DateTime(2020, 1, 1, 23, 59, 59)),
        DateTime(2020, 1, 1, 0, 0, 0));
  });
}
