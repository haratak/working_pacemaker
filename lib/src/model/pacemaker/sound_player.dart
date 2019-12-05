import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';
import 'package:quiver/iterables.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';
import 'package:working_pacemaker/src/model/settings/pacemaker_settings.dart'
    show maxBreakingDuration, maxWorkingDuration;
import 'package:working_pacemaker/src/platform/platform.dart' show Sound;

import 'enums.dart';

class Sounds {
  final Sound _countdown;
  final Sound _countZero;
  final Sound _paceMaking;
  Sounds(
      {@required Sound countdown,
      @required Sound countZero,
      @required Sound paceMaking})
      : assert(countdown != null),
        assert(countZero != null),
        assert(paceMaking != null),
        this._countdown = countdown,
        this._countZero = countZero,
        this._paceMaking = paceMaking;

  void dispose() async {
    unawaited(_countdown.dispose());
    unawaited(_countZero.dispose());
    unawaited(_paceMaking.dispose());
  }
}

/// Sound Player.
///
/// This player does not wait for the sounds to be loaded, because all the
/// sounds are to be certainly loaded before first timing of playing a sound.
///
/// Error handling for failing to load sound is not implemented, because
/// we believe it is not likely to happen on native environment.
/// We would revisit for this potential issue if this app for the web becomes
/// serious production. Because on the web environment,
/// sounds will be loaded over network, which can be failed.
class SoundPlayer {
  final Sounds _sounds;
  final _secondsToPlayCountdown = const [3, 2, 1];
  final _secondToPlayCountZero = 0;

  /// Timings to play Pace making sound on every 10 minutes.
  ///
  /// This range must be valid regardless of
  /// current working / breaking duration settings,
  /// assuming [maxWorkingDuration] is longer than [maxBreakingDuration].
  ///
  /// Since this range is already narrow enough,
  /// handling duration setting changes won't be necessary.
  ///
  /// On right after timer starting / resuming, it shouldn't play the sound.
  /// For that purpose, one second is added on the every element
  /// to skip the timings. Thus, one second delay will be given on the
  /// actual play for the adjustment.
  final _secondsToPlayPaceMaking = range(10, maxWorkingDuration.inMinutes, 10)
      .map((m) => Duration(minutes: m + 1).inSeconds);

  SoundPlayer({@required Sounds sounds})
      : assert(sounds != null),
        _sounds = sounds {
    assert(maxWorkingDuration > maxBreakingDuration);
  }

  void run(Stream<int> remainingSeconds,
      Stream<TimerLifecycleState> timerLifecycleStates) {
    CombineLatestStream.combine2(remainingSeconds, timerLifecycleStates,
            (second, state) => Tuple2<int, TimerLifecycleState>(second, state))
        .where((secondsAndState) =>
            secondsAndState.item2 == TimerLifecycleState.running)
        .map((secondsAndState) => secondsAndState.item1)
        .asBroadcastStream()
          ..where((second) => _secondsToPlayCountdown.contains(second))
              .forEach((_) => _sounds._countdown.play())
          ..where((second) => second == _secondToPlayCountZero)
              .forEach((_) => _sounds._countZero.play())
          ..where((second) => _secondsToPlayPaceMaking.contains(second))
              // 1 second delay to adjust the play timing.
              // See comment of [_secondsToPlayPaceMaking].
              .asyncMap((second) =>
                  Future.delayed(const Duration(seconds: 1), () => second))
              .forEach((_) => _sounds._paceMaking.play());
  }

  void dispose() {
    _sounds.dispose();
  }
}
