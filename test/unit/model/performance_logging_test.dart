import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
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

      test('Add log (when storage value is not null).', () async {
        logger.now = DateTime(2020, 1, 1);
        logger.onWorkingPhaseIsFinished.add(const Duration(minutes: 25));
        // Wait for it will be logged.
        await Future.delayed(Duration.zero);

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
    bool areLogsSorted(List<PerformanceLog> logs) => range(1, logs.length)
        .every((i) => logs[i - 1].finishedTime.isBefore(logs[i].finishedTime));

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

    group('listOfADay.', () {
      group('With no data set.', () {
        test('Empty Logs.', () async {
          logReader.now = DateTime.now();
          final result = await logReader.listOfADay(logReader.now);
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
          final result = await logReader.listOfADay(logReader.now);

          expect(result, isNotEmpty);

          expect(
              result.every((log) => log.finishedTime.day == logReader.now.day),
              isTrue);
        });
        test('Logs are sorted by finishedTime ascendant order.', () async {
          final result = await logReader.listOfADay(logReader.now);
          expect(areLogsSorted(result.toList()), isTrue);
        });
      });
    });
    group('listOfLastSevenDaysFrom.', () {
      group('With no data set', () {
        test('Empty Logs.', () async {
          logReader.now = DateTime.now();
          final result = await logReader.listOfLastSevenDaysFrom(logReader.now);
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
          final result = await logReader.listOfLastSevenDaysFrom(logReader.now);

          expect(result, isNotEmpty);

          final midnightOfSevenDaysAgo =
              midnightOf(logReader.now).subtract(const Duration(days: 7));

          // From 12/29 to 1/4.
          for (final log in result) {
            expect(log.finishedTime.compareTo(midnightOfSevenDaysAgo),
                isNonNegative);
            expect(log.finishedTime.compareTo(logReader.now), isNegative);
          }

          // 12/29
          expect(result.first.finishedTime.day == midnightOfSevenDaysAgo.day,
              isTrue);
          // 1/4
          expect(result.last.finishedTime.day == logReader.now.day, isTrue);
          // 12/31
          expect(
              () => result.firstWhere((log) =>
                  log.finishedTime.day ==
                  endingDayOfThisMonth(midnightOfSevenDaysAgo).day),
              returnsNormally);
          // 1/1
          expect(() => result.firstWhere((log) => log.finishedTime.day == 1),
              returnsNormally);
        });

        test('Logs are sorted by day ascendant order.', () async {
          final result = await logReader.listOfLastSevenDaysFrom(logReader.now);
          expect(areLogsSorted(result.toList()), isTrue);
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
        setUp(() async {
          logReader.now = DateTime(2020, 2, 28);
          final dataSet =
              generator.maximumDataSetOfMonth(logReader.now, untilNow: true);
          await repository.set(logReader.now, dataSet);

          final lastMonthDataSet = generator.maximumDataSetOfMonth(
              beginningDayOfLastMonth(logReader.now),
              untilNow: false);
          await repository.set(
              beginningDayOfLastMonth(logReader.now), lastMonthDataSet);

          final nextMonthDataSet = generator.maximumDataSetOfMonth(
              beginningDayOfNextMonth(logReader.now),
              untilNow: false);
          await repository.set(
              beginningDayOfLastMonth(logReader.now), nextMonthDataSet);
        });
        test('Logs are all in this month.', () async {
          final result = await logReader.listOfThisMonth(logReader.now);

          expect(result, isNotEmpty);

          for (final log in result) {
            expect(
                log.finishedTime
                    .compareTo(beginningDayOfThisMonth(logReader.now)),
                isNonNegative);
            expect(
                log.finishedTime
                    .compareTo(beginningDayOfNextMonth(logReader.now)),
                isNegative);
          }
        });
        test('Logs are sorted by day ascendant order.', () async {
          final result = await logReader.listOfThisMonth(logReader.now);
          expect(areLogsSorted(result.toList()), isTrue);
        });
      });
    });

    group('listOfRest.', () {
      List<DateTime> monthsWithData;

      setUp(() async {
        final today = DateTime(2020, 2, 4);
        logReader.now = today;

        final feb = beginningDayOfThisMonth(today);
        final jan = beginningDayOfLastMonth(today);
        // Across year.
        final dec = beginningDayOfLastMonth(jan);
        final oct = DateTime(dec.year, dec.month - 2, 1);
        final jun = DateTime(oct.year, oct.month - 4, 1);
        // Oldest month.
        final mar = DateTime(jun.year, jun.month - 3, 1);
        // Out of the range.
        final lastFebEnding =
            midnightOf(mar).subtract(const Duration(microseconds: 1));

        monthsWithData = [jan, dec, oct, jun, mar];
        for (final month in monthsWithData) {
          await repository.set(month, [PerformanceLog(month, 50)]);
        }
        // 2 data sets where they are not to be found.
        await repository.set(feb, [PerformanceLog(feb, 50)]);
        await repository
            .set(lastFebEnding, [PerformanceLog(lastFebEnding, 50)]);
      });
      test(
          '11 lists of monthly Log, from one month ago to 11 month ago,'
          'each is empty if no data set.', () async {
        final result = await logReader.listOfRest();
        expect(result.length, 11);

        final months = monthsWithData.map((e) => e.month);
        expect(
            result
                .where((logs) => months.contains(logs.dateTime.month))
                .every((logs) => logs.isNotEmpty),
            isTrue);
        expect(
            result
                .where((logs) => !months.contains(logs.dateTime.month))
                .every((logs) => logs.isEmpty),
            isTrue);
        final foundMonths = result.map((logs) => logs.dateTime.month);
        // 2 data sets of feb and last feb are not found.
        expect(foundMonths, isNot(contains(2)));
      });
    });

    group('restExists.', () {
      group(
          'When at least one log is found'
          'from the end of one month ago to the beginning of 11 month ago.',
          () {
        DateTime thisMonthBeginning;
        setUp(() async {
          final today = DateTime(2020, 2, 4);
          logReader.now = today;

          thisMonthBeginning = midnightOf(beginningDayOfThisMonth(today));
          final onYearAgoEnding = midnightOf(beginningDayOfThisMonth(DateTime(
                  thisMonthBeginning.year,
                  thisMonthBeginning.month - 11,
                  thisMonthBeginning.day)))
              .subtract(const Duration(microseconds: 1));
          // 2 boundary data sets where they are not to be found.
          await repository.set(
              thisMonthBeginning, [PerformanceLog(thisMonthBeginning, 50)]);
          await repository
              .set(onYearAgoEnding, [PerformanceLog(onYearAgoEnding, 50)]);
        });
        test('Returns false when no logs found', () {
          expect(logReader.restExists(), completion(isFalse));
        });
        group('Cases of true.', () {
          Future<void> generateDataSet({@required int monthAgo}) async {
            final dateTime = DateTime(thisMonthBeginning.year,
                thisMonthBeginning.month - monthAgo, thisMonthBeginning.day);
            await repository.set(dateTime, [PerformanceLog(dateTime, 50)]);
          }

          test('With 1 month ago boundary data.', () async {
            final dateTime =
                thisMonthBeginning.subtract(const Duration(microseconds: 1));
            await repository.set(dateTime, [PerformanceLog(dateTime, 50)]);
            expect(logReader.restExists(), completion(isTrue));
          });
          test('With 2 month ago data.', () async {
            await generateDataSet(monthAgo: 2);
            expect(logReader.restExists(), completion(isTrue));
          });
          test('With 3 month ago data.', () async {
            await generateDataSet(monthAgo: 3);
            expect(logReader.restExists(), completion(isTrue));
          });
          test('With 4 month ago data.', () async {
            await generateDataSet(monthAgo: 4);
            expect(logReader.restExists(), completion(isTrue));
          });
          test('With 5 month ago data.', () async {
            await generateDataSet(monthAgo: 5);
            expect(logReader.restExists(), completion(isTrue));
          });
          test('With 6 month ago data.', () async {
            await generateDataSet(monthAgo: 6);
            expect(logReader.restExists(), completion(isTrue));
          });
          test('With 7 month ago data.', () async {
            await generateDataSet(monthAgo: 7);
            expect(logReader.restExists(), completion(isTrue));
          });
          test('With 8 month ago data.', () async {
            await generateDataSet(monthAgo: 8);
            expect(logReader.restExists(), completion(isTrue));
          });
          test('With 9 month ago data.', () async {
            await generateDataSet(monthAgo: 9);
            expect(logReader.restExists(), completion(isTrue));
          });
          test('With 10 month ago data.', () async {
            await generateDataSet(monthAgo: 10);
            expect(logReader.restExists(), completion(isTrue));
          });
          test('With 11 month ago boundary data.', () async {
            await generateDataSet(monthAgo: 11);
            expect(logReader.restExists(), completion(isTrue));
          });
        });
      });
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
