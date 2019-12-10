import 'package:fake_async/fake_async.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:working_pacemaker/src/localization/messages.dart';
import 'package:working_pacemaker/src/model/performance_logging.dart';
import 'package:working_pacemaker/src/model/performance_logging/date_time_helper.dart';
import 'package:working_pacemaker/src/subject/performance_log_page_subject.dart';

import '../mock.dart';

class MockLogReader extends Mock implements LogReader {}

main() {
  group(PerformanceLogPageSubject, () {
    FakeAsync fakeAsyncZone;

    MockLogReader logReader;
    MockAnalytics analytics;
    PerformanceLogPageSubject subject;
    AppMessages messages;
    DateTime today;

    setUp(() {
      fakeAsyncZone = FakeAsync();
      fakeAsyncZone.run((async) {
        today = DateTime(2020, 2, 4);
        logReader = MockLogReader();
        when(logReader.recent()).thenAnswer(
          (_) => Future.value(
            RecentLogs(
              PerformanceLogs(today, []),
              PerformanceLogs(today, []),
              PerformanceLogs(today, []),
            ),
          ),
        );
        when(logReader.restExists()).thenAnswer((_) => Future.value(true));

        analytics = MockAnalytics();
        messages = AppMessages('en_US');
        initializeDateFormatting('en_US', null);
        async.flushMicrotasks();
      });
    });

    group('Inputs.', () {
      group('showAllLogsButtonPressed.', () {
        setUp(() {
          fakeAsyncZone.run((async) {
            when(logReader.listOfRest()).thenAnswer(
              (_) => Future.value(
                [
                  PerformanceLogs(
                    beginningDayOfLastMonth(today),
                    [
                      PerformanceLog(beginningDayOfLastMonth(today), 90),
                      PerformanceLog(
                          beginningDayOfLastMonth(today)
                              .add(const Duration(hours: 1)),
                          90)
                    ],
                  ),
                  PerformanceLogs(
                    beginningDayOfLastMonth(beginningDayOfLastMonth(today)),
                    [
                      PerformanceLog(
                          beginningDayOfLastMonth(
                              beginningDayOfLastMonth(today)),
                          90),
                      PerformanceLog(
                          beginningDayOfLastMonth(
                                  beginningDayOfLastMonth(today))
                              .add(const Duration(hours: 1)),
                          90)
                    ],
                  ),
                ],
              ),
            );
            subject = PerformanceLogPageSubject(
                performanceLogReader: logReader,
                messages: messages,
                analytics: analytics);
          });
        });

        test('Emits the rest of chart view data set.', () {
          fakeAsyncZone.run((async) {
            subject.showAllLogsButtonPressed.add(null);
            subject.listOfRest.listen(expectAsync1((rest) {
              expect(rest.length, 2);
              final first = rest.first;
              expect(first.period, 'January');
              expect(first.totalWorkingTime, '3:00');
              expect(first.dataSet.length, 31);
              expect(first.dataSet.first.y, 3);
              expect(first.dataSet.last.y, 0);
              final second = rest[1];
              expect(second.period, 'December');
              expect(second.totalWorkingTime, '3:00');
              expect(second.dataSet.length, 31);
              expect(second.dataSet.first.y, 3);
              expect(second.dataSet.last.y, 0);
            }, count: 1));
            async.flushMicrotasks();
          });
        });

        test('showViewAllLogsButton emits false.', () {
          fakeAsyncZone.run((async) {
            subject.showAllLogsButtonPressed.add(null);
            async.elapse(const Duration(milliseconds: 500));
            subject.showViewAllLogsButton.listen(expectAsync1((show) {
              expect(show, isFalse);
            }, count: 1));
            async.flushMicrotasks();
          });
        });

        test('Analytics logging: view_all_logs_button_pressed', () {
          fakeAsyncZone.run((async) {
            subject.showAllLogsButtonPressed.add(null);
            async.flushMicrotasks();
            verify(analytics.logEvent(name: 'view_all_logs_button_pressed'))
                .called(1);
          });
        });
      });
    });

    group('Outputs.', () {
      const oneHour = Duration(hours: 1);

      group('today', () {
        setUp(() {
          when(logReader.recent()).thenAnswer(
            (_) => Future.value(
              RecentLogs(
                PerformanceLogs(today, [
                  PerformanceLog(today.add(oneHour), 50),
                  PerformanceLog(today.add(oneHour * 2), 25)
                ]),
                PerformanceLogs(today, []),
                PerformanceLogs(today, []),
              ),
            ),
          );

          subject = PerformanceLogPageSubject(
              performanceLogReader: logReader,
              messages: messages,
              analytics: analytics);
        });

        test('period.', () {
          subject.today.listen(expectAsync1((today) {
            expect(today.period, 'Today');
          }, count: 1));
        });

        test('totalWorkingTime.', () {
          subject.today.listen(expectAsync1((today) {
            expect(today.totalWorkingTime, '1:15');
          }, count: 1));
        });

        test('Padding data set for the chart looking.', () {
          subject.today.listen(expectAsync1((today) {
            expect(today.dataSet.length, 4);
            expect(today.dataSet.first.time.toIso8601String(),
                '2020-02-04T00:00:00.000');
            expect(today.dataSet.first.y, 0);
            expect(today.dataSet.last.time.toIso8601String(),
                '2020-02-05T00:00:00.000');
            expect(today.dataSet.last.y, 0);
          }, count: 1));
        });

        test('Data set from logs.', () {
          subject.today.listen(expectAsync1((today) {
            expect(today.dataSet[1].time.toIso8601String(),
                '2020-02-04T01:00:00.000');
            expect(today.dataSet[1].y, 50);
            expect(today.dataSet[2].time.toIso8601String(),
                '2020-02-04T02:00:00.000');
            expect(today.dataSet[2].y, 25);
          }, count: 1));
        });
      });

      group('lastSevenDays', () {
        setUp(() {
          when(logReader.recent()).thenAnswer(
            (_) {
              final yesterday = today.subtract(const Duration(days: 1));
              final sixDaysAgo = today.subtract(const Duration(days: 6));
              return Future.value(
                RecentLogs(
                  PerformanceLogs(today, []),
                  PerformanceLogs(today, [
                    PerformanceLog(today.add(oneHour), 50),
                    PerformanceLog(today.add(oneHour * 2), 25),
                    PerformanceLog(today.add(oneHour * 3), 50),
                    PerformanceLog(yesterday.add(oneHour), 50),
                    PerformanceLog(yesterday.add(oneHour * 2), 25),
                    PerformanceLog(yesterday.add(oneHour * 3), 50),
                    PerformanceLog(sixDaysAgo.add(oneHour), 50),
                    PerformanceLog(sixDaysAgo.add(oneHour * 2), 25),
                    PerformanceLog(sixDaysAgo.add(oneHour * 3), 50),
                  ]),
                  PerformanceLogs(today, []),
                ),
              );
            },
          );

          subject = PerformanceLogPageSubject(
              performanceLogReader: logReader,
              messages: messages,
              analytics: analytics);
        });

        test('period.', () {
          subject.lastSevenDays.listen(expectAsync1((sevenDays) {
            expect(sevenDays.period, 'Seven Days');
          }, count: 1));
        });

        test('totalWorkingTime.', () {
          subject.lastSevenDays.listen(expectAsync1((sevenDays) {
            expect(sevenDays.totalWorkingTime, '6:15');
          }, count: 1));
        });

        test('Padding data set for the chart looking.', () {
          subject.lastSevenDays.listen(expectAsync1((sevenDays) {
            expect(sevenDays.dataSet.length, 7);
            expect(sevenDays.dataSet.where((data) => data.y == 0).length, 4);
          }, count: 1));
        });

        test('Data set from logs.', () {
          subject.lastSevenDays.listen(expectAsync1((sevenDays) {
            expect(sevenDays.dataSet.first.time.toIso8601String(),
                '2020-01-29T00:00:00.000');
            expect(sevenDays.dataSet.first.y, 2);
            expect(sevenDays.dataSet.last.time.toIso8601String(),
                '2020-02-04T00:00:00.000');
            expect(sevenDays.dataSet.last.y, 2);
            expect(sevenDays.dataSet[5].time.toIso8601String(),
                '2020-02-03T00:00:00.000');
            expect(sevenDays.dataSet.last.y, 2);
          }, count: 1));
        });
      });
      group('thisMonth', () {
        setUp(() {
          when(logReader.recent()).thenAnswer(
            (_) {
              final yesterday = today.subtract(const Duration(days: 1));
              final beginningDay = beginningDayOfThisMonth(today);
              return Future.value(
                RecentLogs(
                  PerformanceLogs(today, []),
                  PerformanceLogs(today, []),
                  PerformanceLogs(today, [
                    PerformanceLog(today.add(oneHour), 50),
                    PerformanceLog(today.add(oneHour * 2), 25),
                    PerformanceLog(today.add(oneHour * 3), 50),
                    PerformanceLog(yesterday.add(oneHour), 50),
                    PerformanceLog(yesterday.add(oneHour * 2), 25),
                    PerformanceLog(yesterday.add(oneHour * 3), 50),
                    PerformanceLog(beginningDay.add(oneHour), 50),
                    PerformanceLog(beginningDay.add(oneHour * 2), 25),
                    PerformanceLog(beginningDay.add(oneHour * 3), 50),
                  ]),
                ),
              );
            },
          );

          subject = PerformanceLogPageSubject(
              performanceLogReader: logReader,
              messages: messages,
              analytics: analytics);
        });

        test('period.', () {
          subject.thisMonth.listen(expectAsync1((thisMonth) {
            expect(thisMonth.period, 'This Month');
          }, count: 1));
        });

        test('totalWorkingTime.', () {
          subject.thisMonth.listen(expectAsync1((thisMonth) {
            expect(thisMonth.totalWorkingTime, '6:15');
          }, count: 1));
        });

        test('Padding data set for the chart looking.', () {
          subject.thisMonth.listen(expectAsync1((thisMonth) {
            expect(thisMonth.dataSet.length, 29);
            expect(thisMonth.dataSet.where((data) => data.y == 0).length, 26);
          }, count: 1));
        });

        test('Data set from logs.', () {
          subject.thisMonth.listen(expectAsync1((thisMonth) {
            expect(thisMonth.dataSet.first.time.toIso8601String(),
                '2020-02-01T00:00:00.000');
            expect(thisMonth.dataSet.first.y, 2);
            expect(thisMonth.dataSet[2].time.toIso8601String(),
                '2020-02-03T00:00:00.000');
            expect(thisMonth.dataSet[2].y, 2);
            expect(thisMonth.dataSet[3].time.toIso8601String(),
                '2020-02-04T00:00:00.000');
            expect(thisMonth.dataSet[3].y, 2);
          }, count: 1));
        });
      });

      group('showViewAllLogsButton', () {
        test('If the rest exists, then showViewAllLogsButton emits true.', () {
          fakeAsyncZone.run((async) {
            when(logReader.restExists()).thenAnswer((_) => Future.value(true));
            subject = PerformanceLogPageSubject(
                performanceLogReader: logReader,
                messages: messages,
                analytics: analytics);
            async.flushMicrotasks();
            subject.showViewAllLogsButton.listen(expectAsync1((show) {
              expect(show, isTrue);
            }, count: 1));
            async.flushMicrotasks();
          });
        });
        test(
            'If the rest does not exist, then showViewAllLogsButton emits false.',
            () {
          fakeAsyncZone.run((async) {
            when(logReader.restExists()).thenAnswer((_) => Future.value(false));
            subject = PerformanceLogPageSubject(
                performanceLogReader: logReader,
                messages: messages,
                analytics: analytics);
            async.flushMicrotasks();
            subject.showViewAllLogsButton.listen(expectAsync1((show) {
              expect(show, isFalse);
            }, count: 1));
            async.flushMicrotasks();
          });
        });
      });

      group('listOfRest', () {
        // It is tested in the showAllLogsButtonPressed test.
      });
    });
  });
}
