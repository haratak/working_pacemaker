import 'dart:async';

import 'enums.dart';
import 'working_breaking_timer.dart';

class AutoPhaseSwitcher {
  final WorkingBreakingTimer _timer;
  final Duration _delay;

  AutoPhaseSwitcher(this._timer, {Duration delay = Duration.zero})
      : _delay = delay;

  void run() {
    _timer.timerLifecycleStates
        .where((e) => e == TimerLifecycleState.finished)
        .forEach((_) => _switchPhase());
  }

  void _switchPhase() {
    Timer(_delay, () {
      _timer.switchPhase();
      _timer.start();
    });
  }
}
