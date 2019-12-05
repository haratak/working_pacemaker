import 'package:quiver/iterables.dart';
import 'package:working_pacemaker/src/flavor_config/production_config.dart';
import 'package:working_pacemaker/src/model/settings/pacemaker_settings.dart'
    as pacemaker show DefaultSettings;

import '../main.dart' as for_integration_testing;

class _DurationChangesTestConfig extends ProductionConfig {
  final pacemaker.DefaultSettings pacemakerDefaultSettings =
      _PacemakerDefaultSettings();
}

// By design of the app, duration settings expect at least 1 minute.
class _PacemakerDefaultSettings extends pacemaker.DefaultSettings {
  final List<Duration> workingDurationOptions =
      range(1, 5, 1).map((m) => Duration(minutes: m)).toList();
  final List<Duration> breakingDurationOptions =
      range(1, 5, 1).map((m) => Duration(minutes: m)).toList();
  final Duration workingDuration = const Duration(minutes: 2);
  final Duration breakingDuration = const Duration(minutes: 1);
  _PacemakerDefaultSettings() : super();
}

main() {
  for_integration_testing.main(config: _DurationChangesTestConfig());
}
