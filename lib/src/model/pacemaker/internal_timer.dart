import 'dart:async';
import 'package:meta/meta.dart';
import 'enums.dart';

class InternalTimer {
  final int initialSeconds;
  final _timerLifecycleController = StreamController<TimerLifecycleState>();
  final _remainingSecondsController = StreamController<int>();
  Timer _timer;

  int _remainingSeconds;
  TimerLifecycleState _lifecycle;

  InternalTimer({@required Duration duration})
      : assert(duration != null),
        initialSeconds = duration.inSeconds {
    _setLifecycle(TimerLifecycleState.initial);
    _setRemainingSeconds(_remainingSeconds = initialSeconds);
  }

  Stream<TimerLifecycleState> get timerLifecycle =>
      _timerLifecycleController.stream;
  Stream<int> get remainingSeconds => _remainingSecondsController.stream;

  void start() => _next(TimerLifecycleState.running);
  void pause() => _next(TimerLifecycleState.paused);
  void resume() => _next(TimerLifecycleState.running);
  void finish() => _next(TimerLifecycleState.finished);

  void dispose() {
    _timer?.cancel();
    _doDispose();
  }

  /// FSM transition. Next state may be emitted.
  void _next(TimerLifecycleState next) {
    switch (_lifecycle) {
      case TimerLifecycleState.initial:
        if (next == TimerLifecycleState.running) {
          _doStart();
        } else if (next == TimerLifecycleState.finished) {
          _doFinish();
        }
        break;
      case TimerLifecycleState.running:
        if (next == TimerLifecycleState.paused) {
          _doPause();
        } else if (next == TimerLifecycleState.finished) {
          _doFinish();
        }
        break;
      case TimerLifecycleState.paused:
        if (next == TimerLifecycleState.running) {
          _doResume();
        } else if (next == TimerLifecycleState.finished) {
          _doFinish();
        }
        break;
      case TimerLifecycleState.finished:
        // noop
        break;
    }
  }

  void _doStart() {
    _setLifecycle(TimerLifecycleState.running);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _setRemainingSeconds(_remainingSeconds - 1);
      if (_remainingSeconds <= 0) finish();
    });
  }

  void _doPause() {
    _timer?.cancel();
    _setLifecycle(TimerLifecycleState.paused);
  }

  void _doResume() {
    _doStart();
  }

  void _doFinish() {
    _timer?.cancel();
    _setLifecycle(TimerLifecycleState.finished);
    _doDispose();
  }

  void _doDispose() {
    _timerLifecycleController.close();
    _remainingSecondsController.close();
  }

  void _setLifecycle(TimerLifecycleState lifecycle) {
    _timerLifecycleController.add(_lifecycle = lifecycle);
  }

  void _setRemainingSeconds(int seconds) {
    _remainingSecondsController.add(_remainingSeconds = seconds);
  }
}
