import 'package:quiver/iterables.dart';
import 'package:working_pacemaker/src/model/settings/pacemaker_settings.dart'
    as pacemaker show DefaultSettings;

import 'flavor_config.dart';

final devConfig = _DevConfig();

class _DevConfig extends FlavorConfig {
  final Flavor flavor = Flavor.dev;
  String get appTitle => 'Dev Mode ${super.appTitle}';
  final pacemaker.DefaultSettings pacemakerDefaultSettings =
      _DevPacemakerDefaultSettings();
}

class _DevPacemakerDefaultSettings extends pacemaker.DefaultSettings {
  final List<Duration> workingDurationOptions =
      range(5, 60, 5).map((m) => Duration(seconds: m)).toList();
  final List<Duration> breakingDurationOptions =
      range(5, 30, 5).map((m) => Duration(seconds: m)).toList();
  final Duration workingDuration = const Duration(seconds: 5);
  final Duration breakingDuration = const Duration(seconds: 5);
  _DevPacemakerDefaultSettings() : super();
}
