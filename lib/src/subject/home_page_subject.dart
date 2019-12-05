import 'dart:async';

import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:working_pacemaker/src/model/pacemaker.dart';
import 'package:working_pacemaker/src/platform/platform.dart';
import 'package:working_pacemaker/src/view/theme_data.dart';

@immutable
class HomePageSubject {
  final _fabPressedController = StreamController();
  final Pacemaker _pacemaker;
  @visibleForTesting
  final Duration backgroundGradientYLerpThrottleDuration =
      const Duration(seconds: 10);
  final Analytics _analytics;

  HomePageSubject(
      {@required Pacemaker pacemaker, @required Analytics analytics})
      : assert(pacemaker != null),
        assert(analytics != null),
        _pacemaker = pacemaker,
        _analytics = analytics {
    _fabPressedController.stream
        .tap((_) =>
            unawaited(_analytics.logEvent(name: 'home_page_fab_is_pressed')))
        .forEach(_pacemaker.startOrToggle.add);
  }

  Sink<void> get onFabPressed => _fabPressedController.sink;

  Stream<bool> get isTimerRunning =>
      _pacemaker.lifecycleStates.map((e) => e == TimerLifecycleState.running);

  Stream<PhaseThemeData> get phaseThemeData => _pacemaker.phases.map((e) =>
      e == Phase.working ? workingPhaseThemeData : breakingPhaseThemeData);

  Stream<double> get backgroundGradientYLerp =>
      _pacemaker.percents.throttle(backgroundGradientYLerpThrottleDuration);

  void dispose() {
    _fabPressedController.close();
  }
}
