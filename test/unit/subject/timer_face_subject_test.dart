import 'dart:async';

import 'package:fake_async/fake_async.dart' hide fakeAsync;
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';
import 'package:working_pacemaker/src/localization/messages.dart';
import 'package:working_pacemaker/src/model/pacemaker.dart';
import 'package:working_pacemaker/src/subject/timer_face_subject.dart';

class MockPacemaker extends Mock implements Pacemaker {}

void main() {
  MockPacemaker pacemaker;
  TimerFaceSubject subject;

  group(TimerFaceSubject, () {
    final messages = AppMessages('ja_JP');

    setUp(() {
      pacemaker = MockPacemaker();
      subject = TimerFaceSubject(pacemaker: pacemaker, messages: messages);
    });

    group('Inputs.', () {
      FakeAsync fakeAsyncZone;
      setUp(() {
        fakeAsyncZone = FakeAsync();

        fakeAsyncZone.run((async) {
          // Reassign is necessary to have them run in fakeAsync zone.
          pacemaker = MockPacemaker();
          subject = TimerFaceSubject(pacemaker: pacemaker, messages: messages);
        });
      });

      group('onTimerFacePressed.', () {
        setUp(() {
          when(pacemaker.startOrToggle)
              .thenReturn(StreamController<void>().sink);
        });
        test('call Pacemaker#startOrToggle.add with null.', () {
          fakeAsyncZone.run((async) {
            subject.onTimerFacePressed.add(null);
            verify(pacemaker.startOrToggle).called(1);
          });
        });
      });

      group('onResetButtonPressed.', () {
        setUp(() {
          when(pacemaker.reset).thenReturn(StreamController<void>().sink);
        });
        test('call Pacemaker#reset.add with null.', () async {
          fakeAsyncZone.run((async) {
            subject.onResetButtonPressed.add(null);
            verify(pacemaker.reset).called(1);
          });
        });
      });
    });

    group('Outputs.', () {
      group('phases', () {
        test('case ${Phase.working}. returns a tuple of the phase.', () {
          when(pacemaker.phases).thenAnswer((_) => Stream.value(Phase.working));
          expect(subject.phases,
              emits(Tuple2(messages.workingPhase, Phase.working)));
        });
        test('case ${Phase.working}. returns a tuple of the phase.', () {
          when(pacemaker.phases)
              .thenAnswer((_) => Stream.value(Phase.breaking));
          expect(subject.phases,
              emits(Tuple2(messages.breakingPhase, Phase.breaking)));
        });
      });

      group('isTimerPaused', () {
        test(
            'returns true only if timerLifecycleStates is ${TimerLifecycleState.paused}.',
            () {
          when(pacemaker.lifecycleStates)
              .thenAnswer((_) => Stream.value(TimerLifecycleState.paused));
          expect(subject.isTimerPaused, emits(isTrue));

          when(pacemaker.lifecycleStates)
              .thenAnswer((_) => Stream.value(TimerLifecycleState.initial));
          expect(subject.isTimerPaused, emits(isFalse));

          when(pacemaker.lifecycleStates)
              .thenAnswer((_) => Stream.value(TimerLifecycleState.running));
          expect(subject.isTimerPaused, emits(isFalse));

          when(pacemaker.lifecycleStates)
              .thenAnswer((_) => Stream.value(TimerLifecycleState.finished));
          expect(subject.isTimerPaused, emits(isFalse));
        });
      });
    });

    group('times', () {
      test('Sample time.', () {
        const sample = Duration(minutes: 60);

        when(pacemaker.remainingSeconds)
            .thenAnswer((_) => Stream.value(sample.inSeconds));
        expect(subject.times, emits('60 : 00'));
      });

      test('Min time.', () {
        const min = Duration.zero;

        when(pacemaker.remainingSeconds)
            .thenAnswer((_) => Stream.value(min.inSeconds - 1));
        expect(subject.times.first, throwsArgumentError);

        when(pacemaker.remainingSeconds)
            .thenAnswer((_) => Stream.value(min.inSeconds));
        expect(subject.times, emits('00 : 00'));
      });

      test('Max time.', () {
        const max = Duration(minutes: 99, seconds: 59);

        when(pacemaker.remainingSeconds).thenAnswer(
            (_) => Stream.value((max + const Duration(seconds: 1)).inSeconds));
        expect(subject.times.first, throwsArgumentError);

        when(pacemaker.remainingSeconds).thenAnswer((_) =>
            Stream.value(const Duration(minutes: 99, seconds: 59).inSeconds));
        expect(subject.times, emits('99 : 59'));
      });
    });

    group('percents', () {
      test('Sample.', () {
        when(pacemaker.percents).thenAnswer((_) => Stream.value(0.42));
        expect(subject.percents, emits(0.42));
      });
      test('Min percent.', () {
        when(pacemaker.percents).thenAnswer((_) => Stream.value(0.0));
        expect(subject.percents, emits(0.0));

        when(pacemaker.percents).thenAnswer((_) => Stream.value(-0.1));
        expect(subject.percents, neverEmits(-0.1));
      });
      test('Max percent.', () {
        when(pacemaker.percents).thenAnswer((_) => Stream.value(1.0));
        expect(subject.percents, emits(1.0));

        when(pacemaker.percents).thenAnswer((_) => Stream.value(1.01));
        expect(subject.percents, neverEmits(1.01));
      });
    });

    group('canShowResetButton', () {
      // Intentionally use Observable.timeInterval(),
      // for introducing the alternative way.
      // Usually, FakeAsync should be first choice
      // because it is deterministic and takes less time to run.
      test(
          'returns true only if timerLifecycleStates is'
          ' ${TimerLifecycleState.paused}, with delay.', () {
        when(pacemaker.lifecycleStates)
            .thenAnswer((_) => Stream.value(TimerLifecycleState.paused));
        Observable(subject.canShowResetButton)
            .timeInterval()
            .listen(expectAsync1((result) {
          expect(result.value, isTrue);
          expect(
              result.interval.inMilliseconds,
              greaterThanOrEqualTo(
                  subject.resetButtonDelayDuration.inMilliseconds));
        }));

        when(pacemaker.lifecycleStates)
            .thenAnswer((_) => Stream.value(TimerLifecycleState.initial));
        Observable(subject.canShowResetButton)
            .timeInterval()
            .listen(expectAsync1((result) {
          expect(result.value, isFalse);
          expect(
              result.interval.inMilliseconds,
              greaterThanOrEqualTo(
                  subject.resetButtonDelayDuration.inMilliseconds));
        }));

        when(pacemaker.lifecycleStates)
            .thenAnswer((_) => Stream.value(TimerLifecycleState.running));
        Observable(subject.canShowResetButton)
            .timeInterval()
            .listen(expectAsync1((result) {
          expect(result.value, isFalse);
          expect(
              result.interval.inMilliseconds,
              greaterThanOrEqualTo(
                  subject.resetButtonDelayDuration.inMilliseconds));
        }));

        when(pacemaker.lifecycleStates)
            .thenAnswer((_) => Stream.value(TimerLifecycleState.finished));
        Observable(subject.canShowResetButton)
            .timeInterval()
            .listen(expectAsync1((result) {
          expect(result.value, isFalse);
          expect(
              result.interval.inMilliseconds,
              greaterThanOrEqualTo(
                  subject.resetButtonDelayDuration.inMilliseconds));
        }));
      });
    });

    group('dispose', () {
      test('test disposed', () {
        expect(() => subject.dispose(), returnsNormally);
      });
    });
  });
}
