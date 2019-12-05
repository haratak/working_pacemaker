import 'package:flutter/widgets.dart';

import 'dev_scripts/dev_mobile_platform.dart';
import 'dev_scripts/dev_scripts.dart';
import 'src/app.dart';
import 'src/flavor_config/dev_config.dart';
import 'src/platform/mobile_platform.dart';

main() async {
  // TODO: find way to run this script outside this entry point.
  try {
    final devStorageInitializers = DevStorageInitializers(DevMobilePlatform());
    await devStorageInitializers.clearSettingsStorage();
    await devStorageInitializers.initializePerformanceLogStorage();
  } catch (error, trace) {
    print('Error on running DevStorageInitializers: $error');
    print(trace);
  }

  runApp(App(platform: mobilePlatform, config: devConfig));
}
