import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';
import 'package:working_pacemaker/src/model/settings/pacemaker_settings.dart'
    as settings;
import 'package:working_pacemaker/src/platform/platform.dart' show Analytics;

import 'analytics_logger.dart';
import 'auto_phase_switcher.dart';
import 'enums.dart';
import 'settings_changed_handler.dart';
import 'sound_player.dart';
import 'working_breaking_timer.dart';

class Pacemaker {
  final _startOrToggleController = PublishSubject<void>();
  final _resetController = PublishSubject<void>();

  final WorkingBreakingTimer _timer;
  final AutoPhaseSwitcher _autoPhaseSwitcher;
  final SettingsChangedHandler _settingsChangedHandler;
  final SoundPlayer _soundPlayer;
  final AnalyticsLogger _analyticsLogger;

  Pacemaker._(this._timer, this._autoPhaseSwitcher,
      this._settingsChangedHandler, this._soundPlayer, this._analyticsLogger) {
    _settingsChangedHandler.run();
    _autoPhaseSwitcher.run();
    _soundPlayer.run(remainingSeconds, lifecycleStates);

    _startOrToggleController
        .throttle((_) => _lifecycleStatesChanged)
        .forEach((_) => _startOrToggle());

    _resetController
        .throttle((_) => _lifecycleStatesChanged)
        .where((_) => _timer.lifecycleState == TimerLifecycleState.paused)
        .forEach((_) => _reset());

    lifecycleStates.forEach(_analyticsLogger.onTimerLifecycleStateChanged.add);
  }

  static Future<Pacemaker> initialize(
      {@required settings.ChangeNotifier notifier,
      @required Sounds sounds,
      @required Analytics analytics}) async {
    assert(notifier != null);
    assert(sounds != null);
    assert(analytics != null);

    final durations = await Future.wait(
        [notifier.workingDurations.first, notifier.breakingDurations.first]);
    assert(durations.first > Duration.zero);
    assert(durations.last > Duration.zero);

    final timer = WorkingBreakingTimer(durations.first, durations.last);
    final autoPhaseSwitcher = AutoPhaseSwitcher(timer);
    final settingsChangedHandler =
        SettingsChangedHandler(timer: timer, notifier: notifier);
    final soundPlayer = SoundPlayer(sounds: sounds);
    final logger = AnalyticsLogger(analytics, timer);
    return Pacemaker._(
        timer, autoPhaseSwitcher, settingsChangedHandler, soundPlayer, logger);
  }

  /// Start timer, or toggle it between pause and resume.
  ///
  /// If the timer has finished, this is ignored.
  /// These inputs are throttled until [lifecycleStates] changes.
  Sink<void> get startOrToggle => _startOrToggleController.sink;

  /// Reset timer.
  ///
  /// These inputs are throttled until [lifecycleStates] changes.
  Sink<void> get reset => _resetController.sink;

  Stream<Phase> get phases => _timer.phases;
  Stream<TimerLifecycleState> get lifecycleStates =>
      _timer.timerLifecycleStates;
  Stream<int> get remainingSeconds => _timer.remainingSeconds;
  Stream<double> get percents => _timer.percents;
  Stream<Duration> get workingPhaseIsFinished => CombineLatestStream.combine2(
          phases,
          lifecycleStates,
          (phase, lifecycleState) => Tuple2(phase, lifecycleState))
      .where((e) =>
          e.item1 == Phase.working && e.item2 == TimerLifecycleState.finished)
      .map((_) => _timer.workingDuration);

  // VisibleForTesting because this would never be called in production code.
  @visibleForTesting
  void dispose() {
    _timer.dispose();
    _soundPlayer.dispose();
    _analyticsLogger.dispose();
    _startOrToggleController.close();
    _resetController.close();
  }

  Stream get _lifecycleStatesChanged => Observable(lifecycleStates)
      .pairwise()
      .firstWhere((pair) => pair.first != pair.last)
      .asStream();

  void _startOrToggle() {
    switch (_timer.lifecycleState) {
      case TimerLifecycleState.initial:
        _timer.start();
        break;
      case TimerLifecycleState.running:
        _timer.pause();
        break;
      case TimerLifecycleState.paused:
        _timer.resume();
        break;
      case TimerLifecycleState.finished:
        // noop.
        break;
    }
  }

  void _reset() {
    _analyticsLogger.resettingStateCache
        .add(Tuple2(_timer.phase, _timer.remainingSecond));
    _timer.reset();
  }
}
