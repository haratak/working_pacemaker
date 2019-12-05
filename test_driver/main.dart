import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:meta/meta.dart';
import 'package:working_pacemaker/src/app.dart';
import 'package:working_pacemaker/src/flavor_config/flavor_config.dart';
import 'package:working_pacemaker/src/platform/mobile_platform.dart';

main({@required FlavorConfig config}) async {
  assert(config != null);

  enableFlutterDriverExtension(handler: (String message) async {
    if (message == 'deviceModelName') {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.model;
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.utsname.machine;
      }
    }

    return null;
  });

  runApp(App(platform: mobilePlatform, config: config));
}
