/// Values of this app's widget keys.
///
/// As well as be imported to libraries in production,
/// this library is intended be imported to libraries for integration testing.
/// Do not import package:flutter libraries here,
/// otherwise test_driver will exit with errors in integration testing.
///
/// For instance, instead of [ValueKey],
/// the every method returns [String] for key value, intentionally.
///
/// TODO: Revisit after static extension method is available.
library widget_key_values;

const homePage = _HomePage();

class _HomePage {
  final floatingActionButton = 'floatingActionButton';
  final settingsButton = 'settingsButton';
  final showChartButton = 'showChartButton';
  final timerFace = const _TimerFace();
  const _HomePage();
}

const timerFace = _TimerFace();

class _TimerFace {
  final workingPhaseText = 'workingPhaseText';
  final breakingPhaseText = 'breakingPhaseText';
  final timeText = 'timeText';
  final blinkingTimeText = 'blinkingTimeText';
  final timerFaceButton = 'timerFaceButton';
  final resetButton = 'resetButton';
  const _TimerFace();
}

const settingsPage = _SettingsPage();

class _SettingsPage {
  final workingDurationText = 'workingDurationText';
  final breakingDurationText = 'breakingDurationText';
  final durationSelectDialog = 'durationSelectDialog';
  const _SettingsPage();
}
