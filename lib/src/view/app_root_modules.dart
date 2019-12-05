import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:working_pacemaker/src/flavor_config/flavor_config.dart';
import 'package:working_pacemaker/src/model/pacemaker.dart';
import 'package:working_pacemaker/src/model/performance_logging.dart'
    as performance_logging;
import 'package:working_pacemaker/src/model/settings.dart';
import 'package:working_pacemaker/src/platform/platform.dart';

class AppRootModules {
  final Platform platform;
  final FlavorConfig config;
  final Analytics analytics;
  final Storage storage;
  final List<NavigatorObserver> navigatorObservers;
  final Pacemaker pacemaker;
  final performance_logging.Logger performanceLogger;
  final PacemakerSettings pacemakerSettings;
  AppRootModules(
      {@required this.platform,
      @required this.config,
      @required this.analytics,
      @required this.storage,
      @required this.navigatorObservers,
      @required this.pacemaker,
      @required this.performanceLogger,
      @required this.pacemakerSettings});
}
