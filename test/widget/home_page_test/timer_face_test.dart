import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:working_pacemaker/src/localization/app_localizations.dart';
import 'package:working_pacemaker/src/localization/messages.dart';
import 'package:working_pacemaker/src/model/pacemaker.dart';
import 'package:working_pacemaker/src/subject/timer_face_subject.dart';
import 'package:working_pacemaker/src/view/home_page/timer_face.dart';
import 'package:working_pacemaker/src/view/widget_key_values.dart';

import '../helper.dart';

// ignore: must_be_immutable
class _MockTimerFaceSubject extends Mock implements TimerFaceSubject {}

class _TimerFaceScreen extends Screen {
  get timerFaceButton => key(timerFace.timerFaceButton);
  get resetButton => key(timerFace.resetButton);
  get time => key(timerFace.timeText);
  get blinkingTime => key(timerFace.blinkingTimeText);
}

void main() {
  final messages = AppMessages('ja_JP');
  final screen = _TimerFaceScreen();
  _MockTimerFaceSubject subject;
  Widget widget;

  void setUpSubjectBaseStubs(_MockTimerFaceSubject subject) {
    when(subject.phases).thenAnswer(
        (_) => Stream.value(Tuple2(messages.workingPhase, Phase.working)));
    when(subject.timesAndIsTimerPaused)
        .thenAnswer((_) => Stream.value(const Tuple2('60 : 00', false)));
    when(subject.percents).thenAnswer((_) => Stream.value(1.0));
  }

  group(TimerFace, () {
    setUp(() async {
      subject = _MockTimerFaceSubject();
      setUpSubjectBaseStubs(subject);

      when(subject.onTimerFacePressed)
          .thenReturn(StreamController<void>().sink);

      widget = MaterialApp(
        localizationsDelegates: [AppLocalizations.delegate],
        home: Directionality(
            textDirection: TextDirection.ltr,
            child: Provider<TimerFaceSubject>.value(
                value: subject, child: TimerFace())),
      );
    });

    testWidgets('${timerFace.timerFaceButton}', (tester) async {
      await pumpWidgetAndSettle(widget, tester);
      await tester.tap(screen.timerFaceButton);
      verify(subject.onTimerFacePressed).called(1);
    });

    group('${timerFace.resetButton}', () {
      setUp(() {
        when(subject.onResetButtonPressed)
            .thenReturn(StreamController<void>().sink);
      });

      testWidgets('Show and tap when subject canShowResetButton is true.',
          (tester) async {
        when(subject.canShowResetButton).thenAnswer((_) => Stream.value(true));
        await pumpWidgetAndSettle(widget, tester);
        await tester.tap(screen.resetButton);
        verify(subject.onResetButtonPressed).called(1);
      });

      testWidgets('Hide when subject canShowResetButton is false.',
          (tester) async {
        when(subject.canShowResetButton).thenAnswer((_) => Stream.value(false));
        await pumpWidgetAndSettle(widget, tester);
        expect(screen.resetButton, findsNothing);
      });
    });

    group('Phase.', () {
      testWidgets('Worknig Phase.', (tester) async {
        when(subject.phases).thenAnswer(
            (_) => Stream.value(Tuple2(messages.workingPhase, Phase.working)));
        await pumpWidgetAndSettle(widget, tester);
        expect(screen.text(messages.workingPhase), findsOneWidget);
      });
      testWidgets('Breaking Phase.', (tester) async {
        when(subject.phases).thenAnswer((_) =>
            Stream.value(Tuple2(messages.breakingPhase, Phase.breaking)));
        await pumpWidgetAndSettle(widget, tester);
        expect(screen.text(messages.breakingPhase), findsOneWidget);
      });
    });

    group(CircularPercentIndicator, () {
      setUp(() {
        when(subject.percents).thenAnswer((_) => Stream.value(0.4));
      });
      testWidgets('Percents.', (tester) async {
        await pumpWidgetAndSettle(widget, tester);
        expect(
            find.byWidgetPredicate((widget) =>
                widget is CircularPercentIndicator && widget.percent == 0.4),
            findsOneWidget);
      });
    });

    group('Time.', () {
      testWidgets('Time, not blinking when the timer is not paused.',
          (tester) async {
        when(subject.timesAndIsTimerPaused)
            .thenAnswer((_) => Stream.value(const Tuple2('20 : 00', false)));
        await pumpWidgetAndSettle(widget, tester);
        expect(screen.time, findsOneWidget);
        expect(screen.text('20 : 00'), findsOneWidget);
      });

      testWidgets('Time, blinking when the timer is paused.', (tester) async {
        when(subject.timesAndIsTimerPaused)
            .thenAnswer((_) => Stream.value(const Tuple2('20 : 00', true)));
        await pumpWidgetAndSettle(widget, tester);
        expect(screen.blinkingTime, findsOneWidget);
        expect(screen.text('20 : 00'), findsOneWidget);
      });
    });
  });
}
