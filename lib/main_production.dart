import 'package:flutter/widgets.dart';
import 'src/app.dart';
import 'src/flavor_config/production_config.dart';
import 'src/platform/mobile_platform.dart';

main() => runApp(App(platform: mobilePlatform, config: productionConfig));
