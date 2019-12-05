import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';
import 'package:working_pacemaker/src/localization/messages.dart';
import 'package:working_pacemaker/src/model/pacemaker.dart';

@immutable
class TimerFaceSubject {
  final Pacemaker _pacemaker;
  final AppMessages _messages;
  @visibleForTesting
  final Duration resetButtonDelayDuration = const Duration(milliseconds: 400);

  TimerFaceSubject(
      {@required Pacemaker pacemaker, @required AppMessages messages})
      : assert(pacemaker != null),
        assert(messages != null),
        _pacemaker = pacemaker,
        _messages = messages;

  Sink<void> get onTimerFacePressed => _pacemaker.startOrToggle;
  Sink<void> get onResetButtonPressed => _pacemaker.reset;

  Stream<Tuple2<String, Phase>> get phases => _pacemaker.phases.map(_phaseView);
  Stream<Tuple2<String, bool>> get timesAndIsTimerPaused =>
      CombineLatestStream.combine2(
          times, isTimerPaused, (one, two) => Tuple2(one, two));
  Stream<double> get percents =>
      _pacemaker.percents.where((e) => e >= 0.0 && e <= 1.0);
  Stream<bool> get canShowResetButton => isTimerPaused
      .asyncMap((e) => Future.delayed(resetButtonDelayDuration, () => e));
  @visibleForTesting
  Stream<bool> get isTimerPaused =>
      _pacemaker.lifecycleStates.map((e) => e == TimerLifecycleState.paused);
  @visibleForTesting
  Stream<String> get times => _pacemaker.remainingSeconds.map(_timeView);

  void dispose() {
    // noop
  }

  Tuple2<String, Phase> _phaseView(Phase phase) {
    switch (phase) {
      case Phase.working:
        return Tuple2(_messages.workingPhase, Phase.working);
      case Phase.breaking:
        return Tuple2(_messages.breakingPhase, Phase.breaking);
      default:
        throw ArgumentError();
    }
  }

  String _timeView(int seconds) {
    final duration = Duration(seconds: seconds);
    final m = duration.inMinutes;
    final s = duration.inSeconds - (m * 60);
    return '${_toDoubleDigitString(m, max: 99)} : ${_toDoubleDigitString(s, max: 59)}';
  }

  String _toDoubleDigitString(int integer, {@required int max}) {
    if (integer >= 0 && integer <= 9) {
      return '0$integer';
    } else if (integer >= 10 && integer <= max) {
      return integer.toString();
    } else {
      throw ArgumentError('Must be "0 <= integer <= $max"');
    }
  }
}
