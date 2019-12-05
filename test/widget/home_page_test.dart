import 'dart:async';

import 'package:fake_async/fake_async.dart' hide fakeAsync;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:working_pacemaker/src/localization/app_localizations.dart';
import 'package:working_pacemaker/src/model/pacemaker.dart';
import 'package:working_pacemaker/src/subject/home_page_subject.dart';
import 'package:working_pacemaker/src/subject/timer_face_subject.dart';
import 'package:working_pacemaker/src/view/home_page.dart';
import 'package:working_pacemaker/src/view/widget_key_values.dart';

import '../unit/mock.dart';
import 'helper.dart';

class _FakeTimerFaceSubject extends Fake implements TimerFaceSubject {
  Stream<Tuple2<String, Phase>> get phases =>
      Stream.value(const Tuple2('fake', Phase.working));
  Stream<Tuple2<String, bool>> get timesAndIsTimerPaused =>
      Stream.value(const Tuple2('fake', true));
  Stream<double> get percents => Stream.value(0.8);
  Stream<bool> get canShowResetButton => Stream.value(true);
  void dispose() {}
}

class _MockPacemaker extends Mock implements Pacemaker {}

class _HomePageScreen extends Screen {
  get floatingActionButton => key(homePage.floatingActionButton);
  get settingsButton => key(homePage.settingsButton);
  get playFAB => find.descendant(
      of: floatingActionButton, matching: find.byIcon(Icons.play_arrow));
  get pauseFAB => find.descendant(
      of: floatingActionButton, matching: find.byIcon(Icons.pause));
}

void main() {
  group('$HomePage, with $HomePageSubject.', () {
    final screen = _HomePageScreen();
    _MockPacemaker pacemaker;
    HomePageSubject subject;
    MockAnalytics analytics;
    Widget widget;

    FakeAsync fakeAsyncZone;

    Future<void> pumpForPendingTimers(tester) async {
      await tester.pump(subject.backgroundGradientYLerpThrottleDuration);
    }

    setUp(() async {
      fakeAsyncZone = FakeAsync();
      pacemaker = _MockPacemaker();
      analytics = MockAnalytics();

      when(pacemaker.startOrToggle).thenReturn(StreamController<void>().sink);
      when(pacemaker.phases).thenAnswer((_) => Stream.value(Phase.working));
      when(pacemaker.lifecycleStates)
          .thenAnswer((_) => Stream.value(TimerLifecycleState.running));
      when(pacemaker.percents).thenAnswer((_) => Stream.value(0.8));
      when(analytics.logEvent(name: anyNamed('name')))
          .thenAnswer((_) => Future.value(null));

      fakeAsyncZone.run((async) {
        subject = HomePageSubject(pacemaker: pacemaker, analytics: analytics);
      });

      widget = MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        routes: {
          '/': (_) {
            return MultiProvider(
              providers: [
                Provider<HomePageSubject>.value(value: subject),
                Provider<TimerFaceSubject>.value(
                    value: _FakeTimerFaceSubject()),
              ],
              child: HomePage(),
            );
          },
          '/settings': (_) {
            return Container(key: const Key('Fake Page'));
          },
        },
      );
    });

    testWidgets(homePage.floatingActionButton, (tester) async {
      await pumpWidgetAndSettle(widget, tester);

      await tester.tap(screen.floatingActionButton);
      verify(pacemaker.startOrToggle).called(1);

      await pumpForPendingTimers(tester);
    });

    testWidgets(homePage.settingsButton, (tester) async {
      await pumpWidgetAndSettle(widget, tester);
      expect(
          find.descendant(
              of: screen.settingsButton, matching: find.byIcon(Icons.settings)),
          findsOneWidget);
      await tester.tap(screen.settingsButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('Fake Page')), findsOneWidget);

      await pumpForPendingTimers(tester);
    });

    testWidgets(homePage.floatingActionButton, (tester) async {
      // ignore: close_sinks
      final timerLifeCycleStateController =
          StreamController<TimerLifecycleState>.broadcast();
      when(pacemaker.lifecycleStates)
          .thenAnswer((_) => timerLifeCycleStateController.stream);

      await pumpWidgetAndSettle(widget, tester);

      timerLifeCycleStateController.add(TimerLifecycleState.running);
      await tester.pumpAndSettle();
      expect(screen.pauseFAB, findsOneWidget);

      timerLifeCycleStateController.add(TimerLifecycleState.initial);
      await tester.pumpAndSettle();
      expect(screen.playFAB, findsOneWidget);

      timerLifeCycleStateController.add(TimerLifecycleState.paused);
      await tester.pumpAndSettle();
      expect(screen.playFAB, findsOneWidget);

      timerLifeCycleStateController.add(TimerLifecycleState.finished);
      await tester.pumpAndSettle();
      expect(screen.playFAB, findsOneWidget);

      await pumpForPendingTimers(tester);
    });
  });
}
