import 'package:meta/meta.dart';
import 'package:working_pacemaker/src/model/settings.dart' show ChangeNotifier;

import 'enums.dart';
import 'working_breaking_timer.dart';

class SettingsChangedHandler {
  final WorkingBreakingTimer _timer;
  final ChangeNotifier _notifier;

  SettingsChangedHandler({
    @required WorkingBreakingTimer timer,
    @required ChangeNotifier notifier,
  })  : assert(timer != null),
        assert(notifier != null),
        _timer = timer,
        _notifier = notifier;

  void run() {
    _notifier
      ..workingDurations.forEach(_handleWorkingDurationChange)
      ..breakingDurations.forEach(_handleBreakingDurationChange);
  }

  void _handleWorkingDurationChange(Duration duration) {
    if (duration == _timer.workingDuration) return;

    _timer.workingDuration = duration;
    if (_timer.phase == Phase.working) _timer.reset(to: Phase.working);
  }

  void _handleBreakingDurationChange(Duration duration) {
    if (duration == _timer.breakingDuration) return;

    _timer.breakingDuration = duration;
    if (_timer.phase == Phase.breaking) _timer.reset(to: Phase.breaking);
  }
}
