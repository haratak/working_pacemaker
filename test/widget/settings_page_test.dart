import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:quiver/iterables.dart';
import 'package:working_pacemaker/src/localization/app_localizations.dart';
import 'package:working_pacemaker/src/localization/messages.dart';
import 'package:working_pacemaker/src/model/pacemaker/enums.dart';
import 'package:working_pacemaker/src/subject/settings_page_subject.dart';
import 'package:working_pacemaker/src/view/settings_page.dart';
import 'package:working_pacemaker/src/view/widget_key_values.dart';

import 'helper.dart';

// ignore: must_be_immutable
class _MockSettingsPageSubject extends Mock implements SettingsPageSubject {}

class _SettingsPageScreen extends Screen {
  final DurationChangeDialogScreen durationChangeDialog =
      DurationChangeDialogScreen();
  get workingDuration => key(settingsPage.workingDurationText);
  get breakingDuration => key(settingsPage.breakingDurationText);
}

class DurationChangeDialogScreen extends Screen {
  get yourself => find.byType(SimpleDialog);
  radioListTileOf(Duration duration) => find.byWidgetPredicate(
      (widget) => widget is RadioListTile && widget.value == duration);
  checkedRadioListTileOf(Duration duration) => find.byWidgetPredicate(
      (widget) =>
          widget is RadioListTile &&
          widget.value == duration &&
          widget.checked);
}

void main() {
  group(SettingsPage, () {
    final screen = _SettingsPageScreen();
    final messages = AppMessages('ja_JP');
    _MockSettingsPageSubject subject;
    Widget widget;

    final workingDurationOptions =
        range(10, 30, 5).map((e) => Duration(minutes: e)).toList();
    final breakingDurationOptions =
        range(5, 20, 5).map((e) => Duration(minutes: e)).toList();

    void setUpBaseStubs(_MockSettingsPageSubject subject) {
      when(subject.workingDurations)
          .thenAnswer((_) => Stream.value(workingDurationOptions.first));
      when(subject.breakingDurations)
          .thenAnswer((_) => Stream.value(breakingDurationOptions.first));
      when(subject.workingDurationOptions).thenAnswer((_) =>
          workingDurationOptions
              .map((e) => DurationOption(e, messages.minutes))
              .toList());
      when(subject.breakingDurationOptions).thenAnswer((_) =>
          breakingDurationOptions
              .map((e) => DurationOption(e, messages.minutes))
              .toList());
    }

    setUp(() async {
      subject = _MockSettingsPageSubject();
      setUpBaseStubs(subject);

      widget = Provider<SettingsPageSubject>.value(
          value: subject,
          child: MaterialApp(
            localizationsDelegates: [AppLocalizations.delegate],
            home: SettingsPage(),
          ));
    });

    testWidgets('${Phase.working} duration setting view.', (tester) async {
      await pumpWidgetAndSettle(widget, tester);
      final duration = await subject.workingDurations.first;
      expect(screen.text(messages.workingDuration), findsOneWidget);
      expect(screen.text(messages.minutes(duration.inMinutes)), findsOneWidget);
    });

    testWidgets('${Phase.breaking} duration setting view.', (tester) async {
      await pumpWidgetAndSettle(widget, tester);
      final duration = await subject.breakingDurations.first;
      expect(screen.text(messages.breakingDuration), findsOneWidget);
      expect(screen.text(messages.minutes(duration.inMinutes)), findsOneWidget);
    });

    group('Duration setting change dialog.', () {
      // Here is no dialog close test, because SimpleDialog is responsible
      // for page back and other dialog actions.

      testWidgets('${Phase.working}', (tester) async {
        await pumpWidgetAndSettle(widget, tester);
        await tester.tap(screen.workingDuration);
        await tester.pumpAndSettle();

        // dialog has been opened.
        expect(screen.durationChangeDialog.yourself, findsOneWidget);
        expect(screen.text(messages.selectDurationOf(messages.workingDuration)),
            findsOneWidget);

        // all options.
        for (final duration in workingDurationOptions) {
          expect(screen.durationChangeDialog.radioListTileOf(duration),
              findsOneWidget);
        }

        // selected option.
        expect(
            screen.durationChangeDialog
                .checkedRadioListTileOf(workingDurationOptions.first),
            findsOneWidget);

        // select another.
        await tester.tap(screen.durationChangeDialog
            .radioListTileOf(workingDurationOptions.last));
        verify(subject.changeWorkingDuration(workingDurationOptions.last))
            .called(1);

        // close dialog.
        await tester.pump(const Duration(milliseconds: 500));
        expect(screen.durationChangeDialog.yourself, findsOneWidget);
        await tester.pumpAndSettle(const Duration(milliseconds: 1));
        expect(screen.durationChangeDialog.yourself, findsNothing);
      });

      testWidgets('${Phase.breaking}', (tester) async {
        await pumpWidgetAndSettle(widget, tester);
        await tester.tap(screen.breakingDuration);
        await tester.pumpAndSettle();

        // dialog has been opened.
        expect(screen.durationChangeDialog.yourself, findsOneWidget);
        expect(
            screen.text(messages.selectDurationOf(messages.breakingDuration)),
            findsOneWidget);

        // all options.
        for (final duration in breakingDurationOptions) {
          expect(screen.durationChangeDialog.radioListTileOf(duration),
              findsOneWidget);
        }

        // selected option.
        expect(
            screen.durationChangeDialog
                .checkedRadioListTileOf(breakingDurationOptions.first),
            findsOneWidget);

        // select another.
        await tester.tap(screen.durationChangeDialog
            .radioListTileOf(breakingDurationOptions.last));
        verify(subject.changeBreakingDuration(breakingDurationOptions.last))
            .called(1);

        // close dialog.
        await tester.pump(const Duration(milliseconds: 500));
        expect(screen.durationChangeDialog.yourself, findsOneWidget);
        await tester.pumpAndSettle(const Duration(milliseconds: 1));
        expect(screen.durationChangeDialog.yourself, findsNothing);
      });
    });
  });
}
