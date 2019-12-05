import 'package:meta/meta.dart';
import 'package:working_pacemaker/src/model/settings/pacemaker_settings.dart'
    as pacemaker show DefaultSettings;

/// Platform independent app level flavor config.
///
/// One can create a subclass for each [Flavor].
@immutable
abstract class FlavorConfig {
  Flavor get flavor;
  final String appTitle = 'Working Pacemaker';
  pacemaker.DefaultSettings get pacemakerDefaultSettings;
}

enum Flavor { dev, integrationTesting, production }
