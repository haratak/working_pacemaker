import 'package:rxdart/rxdart.dart';

import 'enums.dart';
import 'internal_timer.dart';

class WorkingBreakingTimer {
  final _phasesController = BehaviorSubject<Phase>.seeded(Phase.working);
  final _timerLifecycleController =
      BehaviorSubject<TimerLifecycleState>.seeded(TimerLifecycleState.initial);
  final _remainingSecondsController = BehaviorSubject<int>();

  InternalTimer _timer;
  Duration workingDuration;
  Duration breakingDuration;

  WorkingBreakingTimer(
    this.workingDuration,
    this.breakingDuration,
  ) {
    _setUpTimer(phase);
  }

  Stream<Phase> get phases => _phasesController.stream;
  Stream<TimerLifecycleState> get timerLifecycleStates =>
      _timerLifecycleController.stream;
  Stream<int> get remainingSeconds => _remainingSecondsController.stream;
  Stream<double> get percents => remainingSeconds.map(_toPercent);

  TimerLifecycleState get lifecycleState => _timerLifecycleController.value;
  Phase get phase => _phasesController.value;
  int get remainingSecond => _remainingSecondsController.value;

  void start() => _timer.start();
  void pause() => _timer.pause();
  void resume() => _timer.resume();
  void reset({Phase to = Phase.working}) => _setUpTimer(to);

  void switchPhase() =>
      _setUpTimer(phase == Phase.working ? Phase.breaking : Phase.working);

  void dispose() {
    _timer.dispose();
    _phasesController.close();
    _timerLifecycleController.close();
    _remainingSecondsController.close();
  }

  void _setUpTimer(Phase phase) {
    _timer?.dispose();
    _timer = InternalTimer(
        duration: phase == Phase.working ? workingDuration : breakingDuration);

    _phasesController.add(phase);
    _timer.timerLifecycle.listen(_timerLifecycleController.add);
    _timer.remainingSeconds.listen(_remainingSecondsController.add);
  }

  double _toPercent(int seconds) => seconds / _timer.initialSeconds;
}
