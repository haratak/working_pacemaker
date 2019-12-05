import 'package:flutter_driver/flutter_driver.dart';
import 'package:working_pacemaker/src/view/widget_key_values.dart';

abstract class Screen {
  SerializableFinder text(String text) => find.text(text);
}

class HomePageScreen extends Screen {
  final timerFaceButton = find.byValueKey(homePage.timerFace.timerFaceButton);
  final timeText = find.byValueKey(homePage.timerFace.timeText);
  final blinkingTimeText = find.byValueKey(homePage.timerFace.blinkingTimeText);
  final workingPhaseText = find.byValueKey(homePage.timerFace.workingPhaseText);
  final breakingPhaseText =
      find.byValueKey(homePage.timerFace.breakingPhaseText);
  final circularPercentIndicator = find.byType('CircularPercentIndicator');
  final floatingActionButton = find.byValueKey(homePage.floatingActionButton);
  final resetButton = find.byValueKey(homePage.timerFace.resetButton);
  final settingsButton = find.byValueKey(homePage.settingsButton);
  final showChartButton = find.byValueKey(homePage.showChartButton);
}

class SettingsPageScreen extends Screen {
  final workingDurationText = find.byValueKey(settingsPage.workingDurationText);
  final breakingDurationText =
      find.byValueKey(settingsPage.breakingDurationText);
  final durationSelectDialog = _DurationSelectDialog();
  final pageBack = find.pageBack();
}

class _DurationSelectDialog extends Screen {
  final yourself = find.byValueKey(settingsPage.durationSelectDialog);

  text(String text) =>
      find.descendant(of: yourself, matching: super.text(text));
}
