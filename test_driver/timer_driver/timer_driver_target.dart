import 'package:quiver/iterables.dart';
import 'package:working_pacemaker/src/flavor_config/flavor_config.dart';
import 'package:working_pacemaker/src/model/settings/pacemaker_settings.dart'
    as pacemaker show DefaultSettings;

import '../main.dart' as test;

class _TimerTestConfig extends FlavorConfig {
  final Flavor flavor = Flavor.integrationTesting;
  final _TimerTestPacemakerDefaultSettings pacemakerDefaultSettings =
      _TimerTestPacemakerDefaultSettings();
}

class _TimerTestPacemakerDefaultSettings implements pacemaker.DefaultSettings {
  final List<Duration> workingDurationOptions =
      range(5, 10, 1).map((s) => Duration(seconds: s)).toList();
  final List<Duration> breakingDurationOptions =
      range(5, 10, 1).map((s) => Duration(seconds: s)).toList();
  final Duration workingDuration = const Duration(seconds: 10);
  final Duration breakingDuration = const Duration(seconds: 10);
}

main() => test.main(config: _TimerTestConfig());
