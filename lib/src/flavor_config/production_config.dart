import 'package:meta/meta.dart';
import 'package:quiver/iterables.dart';
import 'package:working_pacemaker/src/model/settings/pacemaker_settings.dart'
    as pacemaker
    show
        DefaultSettings,
        maxWorkingDuration,
        maxBreakingDuration,
        minWorkingDuration,
        minBreakingDuration;

import 'flavor_config.dart';

final productionConfig = ProductionConfig();

class ProductionConfig extends FlavorConfig {
  final Flavor flavor = Flavor.production;
  final pacemaker.DefaultSettings pacemakerDefaultSettings =
      ProductionPacemakerDefaultSettings();
}

@visibleForTesting
class ProductionPacemakerDefaultSettings extends pacemaker.DefaultSettings {
  final List<Duration> workingDurationOptions = range(
          pacemaker.minWorkingDuration.inMinutes,
          pacemaker.maxWorkingDuration.inMinutes,
          5)
      .map((m) => Duration(minutes: m))
      .toList();
  final List<Duration> breakingDurationOptions = range(
          pacemaker.minBreakingDuration.inMinutes,
          pacemaker.maxBreakingDuration.inMinutes,
          5)
      .map((m) => Duration(minutes: m))
      .toList();
  final Duration workingDuration = const Duration(minutes: 50);
  final Duration breakingDuration = const Duration(minutes: 10);
  ProductionPacemakerDefaultSettings() : super();
}
