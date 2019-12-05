import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';
import 'package:working_pacemaker/src/localization/messages.dart'
    as localization;
import 'package:working_pacemaker/src/model/pacemaker/enums.dart';
import 'package:working_pacemaker/src/view/widget_key_values.dart';

import '../helper/helper.dart';
import '../screen/screen.dart';

void main() {
  group('Timer test drive.', () {
    FlutterDriver driver;
    Screenshot screenshot;
    localization.AppMessages messages;
    HomePageScreen screen;
    final initialTime = "00 : 10";

    setUpAll(() async {
      messages = localization.AppMessages('en_US');
      screen = HomePageScreen();
      driver = await FlutterDriver.connect();
      final deviceModelName = await driver.requestData('deviceModelName');
      screenshot = Screenshot(driver,
          driverId: 'timer_driver', deviceModelName: deviceModelName);
      printIntegrationTestingWarningMessage();
    });

    setUp(() async {
      expect(await isDriverHealthStatusOk(driver), isTrue);
    });

    test('1. Initial view.', () async {
      await driver.waitFor(screen.circularPercentIndicator);
      await driver.waitFor(screen.floatingActionButton);
      await driver.waitFor(screen.settingsButton);
      await driver.waitFor(screen.showChartButton);
      await driver.waitForAbsent(screen.resetButton);
      expect(await driver.getText(screen.timeText), initialTime);
      expect(
          await driver.getText(screen.workingPhaseText), messages.workingPhase);

      await screenshot.takeAndSaveWithId('1');
    });

    group('2. Basic flythrough, without pausing, resuming, resetting.', () {
      String currentTime = initialTime;
      String previousTime = initialTime;

      void update(String current) {
        previousTime = currentTime;
        currentTime = current;
      }

      setUpAll(() async {
        await driver.waitFor(screen.workingPhaseText);
        await driver.waitForAbsent(screen.resetButton);
        expect(currentTime, initialTime);
        // Play
        await driver.tap(screen.timerFaceButton);
      });

      test('1. Start playing in ${Phase.working}.', () async {
        await Future.delayed(const Duration(seconds: 2), () async {
          expect(await driver.getText(screen.workingPhaseText),
              messages.workingPhase);
          update(await driver.getText(screen.timeText));
          expect(currentTime, isNot(previousTime));
        });
        await screenshot.takeAndSaveWithId('2.1');
      });

      test('2. Playing in ${Phase.breaking}, switched from ${Phase.working}.',
          () async {
        await driver.waitFor(screen.breakingPhaseText,
            timeout: const Duration(seconds: 10));

        expect(await driver.getText(screen.breakingPhaseText),
            messages.breakingPhase);
        update(await driver.getText(screen.timeText));
        expect(currentTime, initialTime);

        await Future.delayed(const Duration(seconds: 2), () async {
          expect(await driver.getText(screen.breakingPhaseText),
              messages.breakingPhase);
          update(await driver.getText(screen.timeText));
          expect(currentTime, isNot(previousTime));
        });
        await screenshot.takeAndSaveWithId('2.2');
      });

      test('3. Playing in ${Phase.working}, switched from ${Phase.breaking}.',
          () async {
        await driver.waitFor(screen.workingPhaseText,
            timeout: const Duration(seconds: 10));

        expect(await driver.getText(screen.workingPhaseText),
            messages.workingPhase);
        update(await driver.getText(screen.timeText));
        expect(currentTime, initialTime);

        await screenshot.takeAndSaveWithId('2.3');
      });

      tearDownAll(() async {
        await driver.tap(screen.timerFaceButton);
        await driver.waitFor(screen.resetButton);
        await driver.tap(screen.resetButton);
      });
    });

    group('3. Reset timer.', () {
      setUpAll(() async {
        await driver.waitFor(screen.workingPhaseText,
            timeout: const Duration(seconds: 10));
        await driver.waitForAbsent(screen.resetButton);
      });

      group('At ${Phase.working}.', () {
        setUpAll(() async {
          await driver.tap(screen.timerFaceButton);
          await Future.delayed(const Duration(seconds: 2));
          await driver.tap(screen.timerFaceButton);
          await driver.waitFor(screen.resetButton);
        });
        test('1. Reset timer.', () async {
          await driver.tap(screen.resetButton);
          await driver.waitForAbsent(screen.resetButton);
          await driver.waitFor(screen.workingPhaseText);
          expect(await driver.getText(screen.timeText), initialTime);

          await screenshot.takeAndSaveWithId('3.1');
        });
      });

      group('At ${Phase.breaking}.', () {
        setUpAll(() async {
          await driver.tap(screen.timerFaceButton);
          await driver.waitFor(screen.breakingPhaseText,
              timeout: const Duration(seconds: 11));
          await driver.tap(screen.timerFaceButton);
          await driver.waitFor(screen.resetButton);
        });
        test('Reset timer.', () async {
          await driver.tap(screen.resetButton);
          await driver.waitForAbsent(screen.resetButton);
          await driver.waitFor(screen.workingPhaseText);
          expect(await driver.getText(screen.timeText), initialTime);

          await screenshot.takeAndSaveWithId('3.2');
        });
      });
    });

    group('4. Pause then resume with button combinations.', () {
      setUpAll(() async {
        await driver.waitFor(screen.workingPhaseText);
        await driver.waitForAbsent(screen.resetButton);
        expect(await driver.getText(screen.timeText), initialTime);
      });

      Future<bool> succeedInPausingThenResumingWithEachButton(
          pauseButtonFinder, resumeButtonFinder) async {
        try {
          await Future.delayed(const Duration(seconds: 1));
          await driver.tap(pauseButtonFinder);
          await driver.waitFor(screen.resetButton);
          await driver.waitFor(screen.blinkingTimeText);
          await driver.waitForAbsent(screen.timeText);

          await Future.delayed(const Duration(seconds: 1));

          await driver.tap(resumeButtonFinder);
          await driver.waitForAbsent(screen.resetButton);
          await driver.waitForAbsent(screen.blinkingTimeText);
          await driver.waitFor(screen.timeText);
          return true;
        } catch (e, trace) {
          print(e);
          print(trace);
          return false;
        }
      }

      group('On ${Phase.working}.', () {
        setUpAll(() async {
          // Play
          await driver.tap(screen.timerFaceButton);
        });

        setUp(() async {
          await Future.delayed(const Duration(seconds: 1));
        });

        test(
            'Pause with ${homePage.timerFace.timerFaceButton},'
            'then resume with ${homePage.timerFace.timerFaceButton}.',
            () async {
          expect(
              await succeedInPausingThenResumingWithEachButton(
                  screen.timerFaceButton, screen.timerFaceButton),
              isTrue);
        });
        test(
            'Pause with ${homePage.timerFace.timerFaceButton},'
            'then resume with ${homePage.floatingActionButton}.', () async {
          expect(
              await succeedInPausingThenResumingWithEachButton(
                  screen.timerFaceButton, screen.floatingActionButton),
              isTrue);
        });
        test(
            'Pause with ${homePage.floatingActionButton},'
            'then resume with ${homePage.timerFace.timerFaceButton}.',
            () async {
          expect(
              await succeedInPausingThenResumingWithEachButton(
                  screen.floatingActionButton, screen.timerFaceButton),
              isTrue);
        });
        test(
            'Pause with ${homePage.floatingActionButton},'
            'then resume with ${homePage.floatingActionButton}.', () async {
          expect(
              await succeedInPausingThenResumingWithEachButton(
                  screen.floatingActionButton, screen.floatingActionButton),
              isTrue);
        });
      });

      group('On ${Phase.breaking}.', () {
        setUpAll(() async {
          await driver.waitFor(screen.breakingPhaseText,
              timeout: const Duration(seconds: 10));
        });

        setUp(() async {
          await Future.delayed(const Duration(seconds: 1));
        });

        test(
            'Pause with ${homePage.timerFace.timerFaceButton},'
            'then resume with ${homePage.timerFace.timerFaceButton}.',
            () async {
          expect(
              await succeedInPausingThenResumingWithEachButton(
                  screen.timerFaceButton, screen.timerFaceButton),
              isTrue);
        });
        test(
            'Pause with ${homePage.timerFace.timerFaceButton},'
            'then resume with ${homePage.floatingActionButton}.', () async {
          expect(
              await succeedInPausingThenResumingWithEachButton(
                  screen.timerFaceButton, screen.floatingActionButton),
              isTrue);
        });
        test(
            'Pause with ${homePage.floatingActionButton},'
            'then resume with ${homePage.timerFace.timerFaceButton}.',
            () async {
          expect(
              await succeedInPausingThenResumingWithEachButton(
                  screen.floatingActionButton, screen.timerFaceButton),
              isTrue);
        });
        test(
            'Pause with ${homePage.floatingActionButton},'
            'then resume with ${homePage.floatingActionButton}.', () async {
          expect(
              await succeedInPausingThenResumingWithEachButton(
                  screen.floatingActionButton, screen.floatingActionButton),
              isTrue);
        });
      });
    });

    tearDownAll(() async {
      await driver?.close();
    });
  });
}
