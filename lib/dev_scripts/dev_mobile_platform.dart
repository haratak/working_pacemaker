import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:working_pacemaker/src/platform/mobile_platform/mobile_platform.dart';
import 'package:working_pacemaker/src/platform/mobile_platform/settings_storage_impl.dart';
import 'package:working_pacemaker/src/platform/mobile_platform/storage_impl.dart';

import 'dev_platform.dart';

class DevMobilePlatform extends MobilePlatform implements DevPlatform {
  @override
  Future<DevSettingsStorage> get settingsStorage =>
      DevSettingsStorageImpl.initialize();

  @override
  Future<DevStorage> get storage => Future.value(DevStorageImpl());
}

class DevSettingsStorageImpl extends SettingsStorageImpl
    implements DevSettingsStorage {
  @protected
  DevSettingsStorageImpl(SharedPreferences preferences) : super(preferences);

  static Future<DevSettingsStorage> initialize() async =>
      DevSettingsStorageImpl(await SharedPreferences.getInstance());

  Future<void> clear() => preferences.clear();
}

class DevStorageImpl extends StorageImpl implements DevStorage {
  Future<void> clear(String namespace) async {
    final directory = Directory(await getDirectoryPath(namespace));
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<void> showStats(String namespace) async {
    final directory = Directory(await getDirectoryPath(namespace));
    if (await directory.exists()) {
      print('--------------------------------');
      print('Sizes of performance logs files:');
      await for (final file in directory.list()) {
        final stat = await file.stat();
        print('${path.basename(file.path)}: ${stat.size}');
      }
      print('--------------------------------');
    } else {
      print('------------------------------------------');
      print('Performance logs directory does not exist.');
      print('------------------------------------------');
      return;
    }
  }
}
