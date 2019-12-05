import 'dart:io' as io;
import 'package:path/path.dart' as path;
import 'package:flutter_driver/flutter_driver.dart';
import 'package:meta/meta.dart';

Future<bool> isDriverHealthStatusOk(FlutterDriver driver) async =>
    (await driver.checkHealth()).status == HealthStatus.ok;

void printIntegrationTestingWarningMessage() {
  print('''
 -----------------------------------------------------------------  
| Deliberately, all tests in this group are NOT independent.      |
| They must run in order from top to bottom with the same driver. |
 -----------------------------------------------------------------
''');
}

class Screenshot {
  final FlutterDriver _driver;
  final String _driverId;
  final String _baseDirectoryToSave;
  final String _deviceModelName;

  Screenshot(this._driver,
      {@required String driverId,
      String baseDirectoryToSave,
      String deviceModelName})
      : assert(driverId != null),
        _driverId = driverId,
        _baseDirectoryToSave =
            baseDirectoryToSave ?? 'test_driver/screenshots/',
        _deviceModelName = deviceModelName ?? 'unknownDeviceModelName';

  Future<void> takeAndSaveWithId(String id) async {
    await _driver.waitUntilNoTransientCallbacks();

    final data = await _driver.screenshot();

    final directory = io.Directory.fromUri(Uri(
        path: path.join(_baseDirectoryToSave, _driverId, _deviceModelName)));

    if (!(await directory.exists())) {
      await directory.create(recursive: true);
    }

    await io.File(path.join(directory.path, '$id.png')).writeAsBytes(data);
  }
}
