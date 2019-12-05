import 'package:fake_async/fake_async.dart' hide fakeAsync;
import 'package:quiver/iterables.dart';
import 'package:test/test.dart';
import 'package:working_pacemaker/src/model/pacemaker/enums.dart';
import 'package:working_pacemaker/src/model/pacemaker/working_breaking_timer.dart';

void main() {
  group(WorkingBreakingTimer, () {
    const workingDuration = Duration(minutes: 25);
    const breakingDuration = Duration(minutes: 5);
    const oneSecond = Duration(seconds: 1);

    FakeAsync fakeAsyncZone;

    WorkingBreakingTimer timer;

    setUp(() {
      fakeAsyncZone = FakeAsync();
      fakeAsyncZone.run((async) {
        timer = WorkingBreakingTimer(workingDuration, breakingDuration);
      });
    });

    test(
        'Timer runs from ${Phase.working},'
        'to ${Phase.breaking}, then ${Phase.working} again.', () {
      fakeAsyncZone.run((async) {
        expect(timer.phases, emits(Phase.working));
        expect(timer.timerLifecycleStates, emits(TimerLifecycleState.initial));
        expect(timer.remainingSeconds, emits(workingDuration.inSeconds));
        expect(timer.percents, emits(1.0));

        timer.start();

        async.elapse(oneSecond);

        expect(timer.phases, emits(Phase.working));
        expect(timer.timerLifecycleStates, emits(TimerLifecycleState.running));
        expect(timer.remainingSeconds, emits(workingDuration.inSeconds - 1));
        expect(timer.percents,
            emits((workingDuration.inSeconds - 1) / workingDuration.inSeconds));

        async.elapse(oneSecond);

        for (final s in range(workingDuration.inSeconds - 2, 0, -1)) {
          expect(timer.phases, emits(Phase.working));
          expect(timer.remainingSeconds, emits(s));
          expect(
              timer.timerLifecycleStates, emits(TimerLifecycleState.running));

          async.elapse(oneSecond);
        }

        expect(timer.phases, emits(Phase.working));
        expect(timer.timerLifecycleStates, emits(TimerLifecycleState.finished));
        expect(timer.remainingSeconds, emits(0));
        expect(timer.percents, emits(0.0));

        // Switching to breaking phase -----------------

        timer.switchPhase();

        async.flushMicrotasks();

        expect(timer.phases, emits(Phase.breaking));
        expect(timer.timerLifecycleStates, emits(TimerLifecycleState.initial));
        expect(timer.remainingSeconds, emits(breakingDuration.inSeconds));
        expect(timer.percents, emits(1.0));

        timer.start();

        async.elapse(oneSecond);

        expect(timer.phases, emits(Phase.breaking));
        expect(timer.timerLifecycleStates, emits(TimerLifecycleState.running));
        expect(timer.remainingSeconds, emits(breakingDuration.inSeconds - 1));
        expect(
            timer.percents,
            emits(
                (breakingDuration.inSeconds - 1) / breakingDuration.inSeconds));

        async.elapse(oneSecond);

        for (final s in range(breakingDuration.inSeconds - 2, 0, -1)) {
          expect(timer.phases, emits(Phase.breaking));
          expect(timer.remainingSeconds, emits(s));
          expect(
              timer.timerLifecycleStates, emits(TimerLifecycleState.running));

          async.elapse(oneSecond);
        }

        expect(timer.phases, emits(Phase.breaking));
        expect(timer.timerLifecycleStates, emits(TimerLifecycleState.finished));
        expect(timer.remainingSeconds, emits(0));
        expect(timer.percents, emits(0.0));

        // Switching to working phase -----------------

        timer.switchPhase();

        async.flushMicrotasks();

        expect(timer.phases, emits(Phase.working));
        expect(timer.timerLifecycleStates, emits(TimerLifecycleState.initial));
        expect(timer.remainingSeconds, emits(workingDuration.inSeconds));
        expect(timer.percents, emits(1.0));

        timer.start();

        async.elapse(oneSecond);

        expect(timer.phases, emits(Phase.working));
        expect(timer.timerLifecycleStates, emits(TimerLifecycleState.running));
        expect(timer.remainingSeconds, emits(workingDuration.inSeconds - 1));
        expect(timer.percents,
            emits((workingDuration.inSeconds - 1) / workingDuration.inSeconds));

        async.flushMicrotasks();
      });
    });

    test('Pause and Resume', () {
      fakeAsyncZone.run((async) {
        timer.start();
        async.elapse(oneSecond);

        final lastRemainingSecondsBeforePaused = workingDuration.inSeconds - 1;
        final lastPercentsBeforePaused =
            (workingDuration.inSeconds - 1) / workingDuration.inSeconds;

        expect(timer.phases, emits(Phase.working));
        expect(timer.timerLifecycleStates, emits(TimerLifecycleState.running));
        expect(timer.remainingSeconds, emits(lastRemainingSecondsBeforePaused));
        expect(timer.percents, emits(lastPercentsBeforePaused));
        timer.pause();

        async.elapse(oneSecond);

        expect(timer.phases, emits(Phase.working));
        expect(timer.timerLifecycleStates, emits(TimerLifecycleState.paused));
        expect(timer.remainingSeconds, emits(lastRemainingSecondsBeforePaused));
        expect(timer.percents, emits(lastPercentsBeforePaused));

        timer.resume();

        async.elapse(oneSecond);

        expect(timer.phases, emits(Phase.working));
        expect(timer.timerLifecycleStates, emits(TimerLifecycleState.running));
        expect(timer.remainingSeconds, emits(workingDuration.inSeconds - 2));
        expect(timer.percents,
            emits((workingDuration.inSeconds - 2) / workingDuration.inSeconds));

        async.flushMicrotasks();
      });
    });

    group('Reset.', () {
      group('At ${Phase.working}.', () {
        test('Reset to working phase.', () {
          fakeAsyncZone.run((async) {
            timer.start();
            async.elapse(oneSecond);
            timer.reset();
            async.flushMicrotasks();

            expect(timer.phases, emits(Phase.working));
            expect(
                timer.timerLifecycleStates, emits(TimerLifecycleState.initial));
            expect(timer.remainingSeconds, emits(workingDuration.inSeconds));
            expect(timer.percents, emits(1.0));

            async.flushMicrotasks();
          });
        });
      });

      group('At ${Phase.breaking}.', () {
        setUp(() {
          fakeAsyncZone.run((async) {
            timer.start();
            async.elapse(workingDuration);
            timer.switchPhase();
            async.flushMicrotasks();
            expect(timer.phases, emits(Phase.breaking));
            expect(timer.remainingSeconds, emits(breakingDuration.inSeconds));
            timer.start();
            async.elapse(oneSecond);
            expect(
                timer.remainingSeconds, emits(breakingDuration.inSeconds - 1));
            async.flushMicrotasks();
          });
        });

        test('Reset to working phase.', () {
          fakeAsyncZone.run((async) {
            timer.reset();
            async.flushMicrotasks();

            expect(timer.phases, emits(Phase.working));
            expect(
                timer.timerLifecycleStates, emits(TimerLifecycleState.initial));
            expect(timer.remainingSeconds, emits(workingDuration.inSeconds));
            expect(timer.percents, emits(1.0));

            async.flushMicrotasks();
          });
        });

        test('Reset to breaking phase.', () {
          fakeAsyncZone.run((async) {
            timer.reset(to: Phase.breaking);
            async.flushMicrotasks();

            expect(timer.phases, emits(Phase.breaking));
            expect(
                timer.timerLifecycleStates, emits(TimerLifecycleState.initial));
            expect(timer.remainingSeconds, emits(breakingDuration.inSeconds));
            expect(timer.percents, emits(1.0));

            async.flushMicrotasks();
          });
        });
      });
    });

    tearDown(() {
      timer.dispose();
    });
  });
}
