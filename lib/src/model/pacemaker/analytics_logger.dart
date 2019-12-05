import 'package:pedantic/pedantic.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';
import 'package:working_pacemaker/src/platform/platform.dart' show Analytics;

import 'enums.dart';
import 'working_breaking_timer.dart';

class AnalyticsLogger {
  final Analytics _analytics;
  final WorkingBreakingTimer _timer;
  final _controller = PublishSubject<TimerLifecycleState>();
  final _resettingStateController = BehaviorSubject<Tuple2<Phase, int>>();

  AnalyticsLogger(this._analytics, this._timer) {
    _controller.pairwise()
      ..where((pair) => pair.first == TimerLifecycleState.initial && pair.last == TimerLifecycleState.running)
          .forEach(
              (_) => _logTimerStarted(_timer.phase, _timer.remainingSecond))
      ..where((pair) => pair.first == TimerLifecycleState.running && pair.last == TimerLifecycleState.paused)
          .forEach((_) => _logTimerPaused(_timer.phase, _timer.remainingSecond))
      ..where((pair) => pair.first == TimerLifecycleState.paused && pair.last == TimerLifecycleState.running)
          .forEach(
              (_) => _logTimerResumed(_timer.phase, _timer.remainingSecond))
      ..where((pair) => pair.first == TimerLifecycleState.paused && pair.last == TimerLifecycleState.initial)
          .forEach((_) => _logTimerReset(_resettingStateController.value.item1,
              _resettingStateController.value.item2));
  }

  Sink<TimerLifecycleState> get onTimerLifecycleStateChanged =>
      _controller.sink;

  Sink<Tuple2<Phase, int>> get resettingStateCache =>
      _resettingStateController.sink;

  void _logTimerStarted(Phase phase, int remainingSeconds) async {
    assert(phase != null);
    assert(remainingSeconds != null);
    unawaited(_analytics.logEvent(name: 'timer_started', parameters: {
      'phase': phase.toString(),
      'remaining_minutes': _secondsToMinutes(remainingSeconds)
    }));
  }

  void _logTimerPaused(Phase phase, int remainingSeconds) async {
    assert(phase != null);
    assert(remainingSeconds != null);
    unawaited(_analytics.logEvent(name: 'timer_paused', parameters: {
      'phase': phase.toString(),
      'remaining_minutes': _secondsToMinutes(remainingSeconds)
    }));
  }

  void _logTimerResumed(Phase phase, int remainingSeconds) async {
    assert(phase != null);
    assert(remainingSeconds != null);
    unawaited(_analytics.logEvent(name: 'timer_resumed', parameters: {
      'phase': phase.toString(),
      'remaining_minutes': _secondsToMinutes(remainingSeconds)
    }));
  }

  void _logTimerReset(Phase phase, int remainingSeconds) async {
    assert(phase != null);
    assert(remainingSeconds != null);
    unawaited(_analytics.logEvent(name: 'timer_reset', parameters: {
      'phase': phase.toString(),
      'remaining_minutes': _secondsToMinutes(remainingSeconds)
    }));
  }

  int _secondsToMinutes(int seconds) => Duration(seconds: seconds).inMinutes;

  void dispose() {
    _controller.close();
    _resettingStateController.close();
  }
}
