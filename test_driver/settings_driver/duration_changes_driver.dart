import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';
import 'package:working_pacemaker/src/localization/messages.dart'
    as localization;
import 'package:working_pacemaker/src/model/pacemaker.dart' show Phase;

import '../helper/helper.dart';
import '../screen/screen.dart';

void main() {
  group('Duration settings change, test drive.', () {
    FlutterDriver driver;
    localization.AppMessages messages;
    SettingsPageScreen settingsPageScreen;
    HomePageScreen homePageScreen;

    setUpAll(() async {
      messages = localization.AppMessages('ja_JP');
      settingsPageScreen = SettingsPageScreen();
      homePageScreen = HomePageScreen();
      driver = await FlutterDriver.connect();
      printIntegrationTestingWarningMessage();
    });

    setUp(() async {
      expect(await isDriverHealthStatusOk(driver), isTrue);
    });

    group('On ${Phase.working}.', () {
      test('1. Working duration change causes timer reset.', () async {
        final timeText = await driver.getText(homePageScreen.timeText);

        await driver.tap(homePageScreen.timerFaceButton);
        await Future.delayed(const Duration(seconds: 2));

        await driver.tap(homePageScreen.settingsButton);

        expect(await driver.getText(settingsPageScreen.workingDurationText),
            messages.minutes(2));

        // Change working duration.
        await driver.tap(settingsPageScreen.workingDurationText);

        await driver.waitFor(settingsPageScreen.durationSelectDialog.yourself);
        await driver.tap(
            settingsPageScreen.durationSelectDialog.text(messages.minutes(1)));

        expect(await driver.getText(settingsPageScreen.workingDurationText),
            messages.minutes(1));

        await driver.tap(settingsPageScreen.pageBack);

        // Confirm the timer is reset, and not running.
        final currentTimeText = await driver.getText(homePageScreen.timeText);

        expect(currentTimeText, isNot(timeText));

        await Future.delayed(const Duration(seconds: 2));

        expect(await driver.getText(homePageScreen.timeText), currentTimeText);
      });

      test('2. Breaking duration change does not cause timer reset.', () async {
        final timeText = await driver.getText(homePageScreen.timeText);

        await driver.tap(homePageScreen.timerFaceButton);
        await Future.delayed(const Duration(seconds: 2));

        await driver.tap(homePageScreen.settingsButton);

        expect(await driver.getText(settingsPageScreen.breakingDurationText),
            messages.minutes(1));

        // Change breaking duration.
        await driver.tap(settingsPageScreen.breakingDurationText);

        await driver.waitFor(settingsPageScreen.durationSelectDialog.yourself);
        await driver.tap(
            settingsPageScreen.durationSelectDialog.text(messages.minutes(2)));

        expect(await driver.getText(settingsPageScreen.breakingDurationText),
            messages.minutes(2));

        await driver.tap(settingsPageScreen.pageBack);

        // Confirm the timer is NOT reset, and still running.
        final currentTimeText = await driver.getText(homePageScreen.timeText);

        expect(currentTimeText, isNot(timeText));

        await Future.delayed(const Duration(seconds: 2));

        expect(await driver.getText(homePageScreen.timeText),
            isNot(currentTimeText));
      });
    });

    group('On ${Phase.breaking}.', () {
      setUpAll(() async {
        // Wait for breaking phase, assuming the timer has been running
        // 1 minute in working phase, and switched to breaking phase.
        // The breaking phase duration is currently 2 minute,
        // and the working phase duration is currently 1 minute,
        // due to previous consecutive test operation.
        await driver.waitFor(homePageScreen.breakingPhaseText,
            timeout: const Duration(minutes: 1));
      });

      test('3. Breaking duration change causes timer reset.', () async {
        final timeText = await driver.getText(homePageScreen.timeText);

        await Future.delayed(const Duration(seconds: 2));

        await driver.tap(homePageScreen.settingsButton);

        expect(await driver.getText(settingsPageScreen.breakingDurationText),
            messages.minutes(2));

        // Change breaking duration.
        await driver.tap(settingsPageScreen.breakingDurationText);

        await driver.waitFor(settingsPageScreen.durationSelectDialog.yourself);
        await driver.tap(
            settingsPageScreen.durationSelectDialog.text(messages.minutes(1)));

        expect(await driver.getText(settingsPageScreen.breakingDurationText),
            messages.minutes(1));

        await driver.tap(settingsPageScreen.pageBack);

        // Confirm the timer is reset, and not running.
        final currentTimeText = await driver.getText(homePageScreen.timeText);

        expect(currentTimeText, isNot(timeText));

        await Future.delayed(const Duration(seconds: 2));

        expect(await driver.getText(homePageScreen.timeText), currentTimeText);
      });

      test('4. Working duration change does not cause timer reset.', () async {
        final timeText = await driver.getText(homePageScreen.timeText);

        await driver.tap(homePageScreen.timerFaceButton);
        await Future.delayed(const Duration(seconds: 2));

        await driver.tap(homePageScreen.settingsButton);

        expect(await driver.getText(settingsPageScreen.workingDurationText),
            messages.minutes(1));

        // Change working duration.
        await driver.tap(settingsPageScreen.workingDurationText);

        await driver.waitFor(settingsPageScreen.durationSelectDialog.yourself);
        await driver.tap(
            settingsPageScreen.durationSelectDialog.text(messages.minutes(2)));

        expect(await driver.getText(settingsPageScreen.workingDurationText),
            messages.minutes(2));

        await driver.tap(settingsPageScreen.pageBack);

        // Confirm the timer is NOT reset, and still running.
        final currentTimeText = await driver.getText(homePageScreen.timeText);

        expect(currentTimeText, isNot(timeText));

        await Future.delayed(const Duration(seconds: 2));

        expect(await driver.getText(homePageScreen.timeText),
            isNot(currentTimeText));
      });
    });

    tearDownAll(() async {
      await driver?.close();
    });
  });
}
