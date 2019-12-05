import 'package:fake_async/fake_async.dart' hide fakeAsync;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:working_pacemaker/src/model/pacemaker.dart';
import 'package:working_pacemaker/src/model/pacemaker/sound_player.dart';
import 'package:working_pacemaker/src/model/settings/pacemaker_settings.dart';
import 'package:working_pacemaker/src/platform/platform.dart' show Sound;

import '../mock.dart';

class MockSound extends Mock implements Sound {}

void main() {
  group(Pacemaker, () {
    const workingDuration = Duration(minutes: 50);
    const breakingDuration = Duration(minutes: 30);
    const oneSecond = Duration(seconds: 1);

    FakeAsync fakeAsyncZone;

    Pacemaker pacemaker;
    ChangeNotifier notifier;
    MockSound mockCountdownSound;
    MockSound mockCountZeroSound;
    MockSound mockPaceMakingSound;
    MockAnalytics mockAnalytics;

    setUp(() {
      fakeAsyncZone = FakeAsync();
      fakeAsyncZone.run((async) {
        notifier = ChangeNotifier();
        mockCountdownSound = MockSound();
        mockCountZeroSound = MockSound();
        mockPaceMakingSound = MockSound();
        mockAnalytics = MockAnalytics();

        notifier.workingDurationsController.add(workingDuration);
        notifier.breakingDurationsController.add(breakingDuration);

        Pacemaker.initialize(
                notifier: notifier,
                sounds: Sounds(
                    countdown: mockCountdownSound,
                    countZero: mockCountZeroSound,
                    paceMaking: mockPaceMakingSound),
                analytics: mockAnalytics)
            .then((instance) {
          pacemaker = instance;
          async.flushMicrotasks();
        });

        async.flushMicrotasks();
      });
    });

    tearDown(() {
      pacemaker.dispose();
      notifier.dispose();
    });

    test("Start, Pause, Resume, Reset", () {
      // Skip most of basic tests because the test for [InternalGroupedTimer] does.
      fakeAsyncZone.run((async) {
        Future.microtask(() {
          expect(pacemaker.lifecycleStates, emits(TimerLifecycleState.initial));

          pacemaker.startOrToggle.add(null); // Start.
          async.flushMicrotasks();
          expect(pacemaker.lifecycleStates, emits(TimerLifecycleState.running));

          pacemaker.startOrToggle.add(null); // Pause.
          async.flushMicrotasks();
          expect(pacemaker.lifecycleStates, emits(TimerLifecycleState.paused));

          pacemaker.startOrToggle.add(null); // Resume.
          async.flushMicrotasks();
          expect(pacemaker.lifecycleStates, emits(TimerLifecycleState.running));

          pacemaker.reset.add(null);
          async.flushMicrotasks();
          expect(pacemaker.lifecycleStates, emits(TimerLifecycleState.initial));

          async.flushMicrotasks();
        });
      });
    });

    test('Switch phase automatically on a timer of phase finished', () async {
      fakeAsyncZone.run((async) {
        pacemaker.startOrToggle.add(null);

        async.elapse(workingDuration);

        // Timer automatically switching to breaking phase then run.
        expect(pacemaker.remainingSeconds, emits(breakingDuration.inSeconds));
        expect(pacemaker.phases, emitsThrough(Phase.breaking));
        expect(pacemaker.lifecycleStates,
            emitsThrough(TimerLifecycleState.running));

        async.elapse(breakingDuration);

        // Timer automatically switching to working phase then run.
        expect(pacemaker.remainingSeconds, emits(workingDuration.inSeconds));
        expect(pacemaker.phases, emitsThrough(Phase.working));
        expect(pacemaker.lifecycleStates,
            emitsThrough(TimerLifecycleState.running));

        async.flushMicrotasks();
      });
    });

    group('Tesing workingDuration changed,', () {
      group('Timer has started, and the phase is ${Phase.working}', () {
        const durationToChange = Duration(minutes: 3);

        setUp(() {
          fakeAsyncZone.run((async) {
            expect(pacemaker.phases, emits(Phase.working));
            pacemaker.startOrToggle.add(null);
            async.flushMicrotasks();
          });
        });

        group('with changed workingDuration', () {
          setUp(() {
            fakeAsyncZone.run((async) {
              notifier.workingDurationsController.add(durationToChange);
              async.flushMicrotasks();
            });
          });

          test('timer is reset, and timer will not automatically start.', () {
            fakeAsyncZone.run((async) {
              expect(pacemaker.phases, emits(Phase.working));
              expect(pacemaker.lifecycleStates,
                  emits(TimerLifecycleState.initial));
              expect(pacemaker.remainingSeconds,
                  emits(durationToChange.inSeconds));
              expect(pacemaker.percents, emits(1.0));

              async.elapse(oneSecond);

              expect(pacemaker.phases, emits(Phase.working));
              expect(pacemaker.lifecycleStates,
                  emits(TimerLifecycleState.initial));
              expect(pacemaker.remainingSeconds,
                  emits(durationToChange.inSeconds));
              expect(pacemaker.percents, emits(1.0));

              async.flushMicrotasks();
            });
          });
        });

        group('with changed breakingDuration', () {
          setUp(() {
            fakeAsyncZone.run((async) {
              notifier.breakingDurationsController.add(durationToChange);
              async.flushMicrotasks();
            });
          });

          test(
              'timer continues,'
              ' and will start breaking phase with the changed breakingDuration.',
              () {
            fakeAsyncZone.run((async) {
              expect(pacemaker.phases, emits(Phase.working));
              expect(pacemaker.lifecycleStates,
                  emits(TimerLifecycleState.running));

              async.elapse(workingDuration);

              expect(pacemaker.phases, emits(Phase.breaking));
              expect(pacemaker.lifecycleStates,
                  emits(TimerLifecycleState.running));
              expect(pacemaker.remainingSeconds,
                  emits(durationToChange.inSeconds));

              async.flushMicrotasks();
            });
          });
        });
      });
    });

    group('Tesing breakingDuration changed,', () {
      group('Timer has started, and the phase becomes ${Phase.breaking}', () {
        const durationToChange = Duration(minutes: 3);

        setUp(() {
          fakeAsyncZone.run((async) {
            expect(pacemaker.phases, emits(Phase.working));
            pacemaker.startOrToggle.add(null);
            async.elapse(workingDuration);
            expect(pacemaker.phases, emits(Phase.breaking));
            expect(
                pacemaker.lifecycleStates, emits(TimerLifecycleState.running));
            expect(
                pacemaker.remainingSeconds, emits(breakingDuration.inSeconds));
            async.flushMicrotasks();
          });
        });

        group('with changed breakingDuration', () {
          setUp(() {
            fakeAsyncZone.run((async) {
              notifier.breakingDurationsController.add(durationToChange);
              async.flushMicrotasks();
            });
          });

          test('timer is reset, and timer will not automatically start.', () {
            fakeAsyncZone.run((async) {
              expect(pacemaker.phases, emits(Phase.breaking));
              expect(pacemaker.lifecycleStates,
                  emits(TimerLifecycleState.initial));
              expect(pacemaker.remainingSeconds,
                  emits(durationToChange.inSeconds));
              expect(pacemaker.percents, emits(1.0));

              async.elapse(oneSecond);

              expect(pacemaker.phases, emits(Phase.breaking));
              expect(pacemaker.lifecycleStates,
                  emits(TimerLifecycleState.initial));
              expect(pacemaker.remainingSeconds,
                  emits(durationToChange.inSeconds));
              expect(pacemaker.percents, emits(1.0));

              async.flushMicrotasks();
            });
          });
        });

        group('with changed workingDuration', () {
          setUp(() {
            fakeAsyncZone.run((async) {
              notifier.workingDurationsController.add(durationToChange);
              async.flushMicrotasks();
            });
          });

          test(
              'timer continues,'
              ' and will start working phase with the changed workingDuration.',
              () {
            fakeAsyncZone.run((async) {
              expect(pacemaker.phases, emits(Phase.breaking));
              expect(pacemaker.lifecycleStates,
                  emits(TimerLifecycleState.running));

              async.elapse(breakingDuration);

              expect(pacemaker.phases, emits(Phase.working));
              expect(pacemaker.lifecycleStates,
                  emits(TimerLifecycleState.running));
              expect(pacemaker.remainingSeconds,
                  emits(durationToChange.inSeconds));

              async.flushMicrotasks();
            });
          });
        });
      });
    });

    group('Sound play.', () {
      group('Countdown and count zero sound.', () {
        test('Play in ${Phase.working}.', () {
          fakeAsyncZone.run((async) {
            expect(pacemaker.phases, emits(Phase.working));
            expect(
                pacemaker.remainingSeconds, emits(workingDuration.inSeconds));

            pacemaker.startOrToggle.add(null);

            async.elapse(workingDuration - const Duration(seconds: 3));

            verify(mockCountdownSound.play()).called(1);

            async.elapse(const Duration(seconds: 1));

            verify(mockCountdownSound.play()).called(1);

            async.elapse(const Duration(seconds: 1));

            verify(mockCountdownSound.play()).called(1);

            async.elapse(const Duration(seconds: 1));

            verify(mockCountZeroSound.play()).called(1);

            async.flushMicrotasks();
          });
        });

        test('Play in ${Phase.breaking}.', () {
          fakeAsyncZone.run((async) {
            expect(pacemaker.phases, emits(Phase.working));
            expect(
                pacemaker.remainingSeconds, emits(workingDuration.inSeconds));

            pacemaker.startOrToggle.add(null);

            async.elapse(workingDuration);

            clearInteractions(mockCountdownSound);
            clearInteractions(mockCountZeroSound);

            async.elapse(breakingDuration - const Duration(seconds: 3));

            verify(mockCountdownSound.play()).called(1);

            async.elapse(const Duration(seconds: 1));

            verify(mockCountdownSound.play()).called(1);

            async.elapse(const Duration(seconds: 1));

            verify(mockCountdownSound.play()).called(1);

            async.elapse(const Duration(seconds: 1));

            verify(mockCountZeroSound.play()).called(1);

            async.flushMicrotasks();
          });
        });
      });

      group('Pace Making', () {
        test('Play in ${Phase.working}.', () {
          fakeAsyncZone.run((async) {
            expect(pacemaker.phases, emits(Phase.working));
            expect(
                pacemaker.remainingSeconds, emits(workingDuration.inSeconds));

            pacemaker.startOrToggle.add(null);
            async.flushMicrotasks();
            // Don't play right after the starting.
            verifyNever(mockPaceMakingSound.play());

            // Play every 10 minutes.
            async.elapse(const Duration(minutes: 10));
            verify(mockPaceMakingSound.play()).called(1);
            async.elapse(const Duration(minutes: 10));
            verify(mockPaceMakingSound.play()).called(1);

            pacemaker.startOrToggle.add(null); // Pause.
            async.flushMicrotasks();
            pacemaker.startOrToggle.add(null); // Resume.
            async.flushMicrotasks();
            // Don't play right after the resuming.
            verifyNever(mockPaceMakingSound.play());

            // Play every 10 minutes.
            async.elapse(const Duration(minutes: 10));
            verify(mockPaceMakingSound.play()).called(1);
            async.elapse(const Duration(minutes: 10));
            verify(mockPaceMakingSound.play()).called(1);

            async.elapse(const Duration(minutes: 10));
            async.flushMicrotasks();
            // Don't play on count zero.
            verifyNever(mockPaceMakingSound.play());
          });
        });
        test('Play in ${Phase.breaking}.', () {
          fakeAsyncZone.run((async) {
            expect(pacemaker.phases, emits(Phase.working));
            expect(
                pacemaker.remainingSeconds, emits(workingDuration.inSeconds));

            pacemaker.startOrToggle.add(null);
            async.elapse(workingDuration - oneSecond);
            async.flushMicrotasks();
            clearInteractions(mockPaceMakingSound);
            async.elapse(oneSecond);
            async.flushMicrotasks();
            // Don't play right after the switching.
            verifyNever(mockPaceMakingSound.play());
            expect(pacemaker.phases, emits(Phase.breaking));

            // Play every 10 minutes.
            async.elapse(const Duration(minutes: 10));
            verify(mockPaceMakingSound.play()).called(1);

            pacemaker.startOrToggle.add(null); // Pause.
            async.flushMicrotasks();
            pacemaker.startOrToggle.add(null); // Resume.
            async.flushMicrotasks();
            // Don't play right after the resuming.
            verifyNever(mockPaceMakingSound.play());

            // Play every 10 minutes.
            async.elapse(const Duration(minutes: 10));
            verify(mockPaceMakingSound.play()).called(1);

            async.elapse(const Duration(minutes: 10));
            async.flushMicrotasks();
            // Don't play on count zero.
            verifyNever(mockPaceMakingSound.play());
          });
        });
      });
    });

    group('Analytics Logger.', () {
      const threeSeconds = Duration(seconds: 3);

      test("Logging in ${Phase.working}.", () {
        fakeAsyncZone.run((async) {
          Future.microtask(() {
            pacemaker.startOrToggle.add(null); // Start.
            verify(mockAnalytics.logEvent(name: 'timer_started', parameters: {
              'phase': Phase.working.toString(),
              'remaining_minutes': workingDuration.inMinutes
            })).called(1);

            async.elapse(threeSeconds);

            pacemaker.startOrToggle.add(null); // Pause.
            pacemaker.remainingSeconds.first.then(expectAsync1((_) {
              verify(mockAnalytics.logEvent(name: 'timer_paused', parameters: {
                'phase': Phase.working.toString(),
                'remaining_minutes': (workingDuration - threeSeconds).inMinutes
              })).called(1);
            }));

            async.elapse(threeSeconds);

            pacemaker.startOrToggle.add(null); // Resume.
            pacemaker.remainingSeconds.first.then(expectAsync1((_) {
              verify(mockAnalytics.logEvent(name: 'timer_resumed', parameters: {
                'phase': Phase.working.toString(),
                'remaining_minutes': (workingDuration - threeSeconds).inMinutes
              })).called(1);
            }));

            pacemaker.reset.add(null);
            pacemaker.remainingSeconds.first.then(expectAsync1((_) {
              verify(mockAnalytics.logEvent(name: 'timer_reset', parameters: {
                'phase': Phase.working.toString(),
                'remaining_minutes': (workingDuration - threeSeconds).inMinutes
              })).called(1);
            }));

            async.flushMicrotasks();
          });
        });
      });

      test("Logging in ${Phase.breaking}.", () {
        fakeAsyncZone.run((async) {
          Future.microtask(() {
            pacemaker.startOrToggle.add(null); // Start.

            // Switch to breaking phase.
            async.elapse(workingDuration);

            async.elapse(threeSeconds);

            pacemaker.startOrToggle.add(null); // Pause.
            pacemaker.remainingSeconds.first.then(expectAsync1((_) {
              verify(mockAnalytics.logEvent(name: 'timer_paused', parameters: {
                'phase': Phase.breaking.toString(),
                'remaining_minutes': (breakingDuration - threeSeconds).inMinutes
              })).called(1);
            }));

            async.elapse(threeSeconds);

            pacemaker.startOrToggle.add(null); // Resume.
            pacemaker.remainingSeconds.first.then(expectAsync1((_) {
              verify(mockAnalytics.logEvent(name: 'timer_resumed', parameters: {
                'phase': Phase.breaking.toString(),
                'remaining_minutes': (breakingDuration - threeSeconds).inMinutes
              })).called(1);
            }));

            pacemaker.reset.add(null);

            pacemaker.remainingSeconds.first.then(expectAsync1((_) {
              verify(mockAnalytics.logEvent(name: 'timer_reset', parameters: {
                'phase': Phase.breaking.toString(),
                'remaining_minutes': (breakingDuration - threeSeconds).inMinutes
              })).called(1);
            }));

            async.flushMicrotasks();
          });
        });
      });
    });
  });
}
