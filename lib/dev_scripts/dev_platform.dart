import 'package:working_pacemaker/src/platform/platform.dart';

abstract class DevPlatform extends Platform {
  @override
  Future<DevSettingsStorage> get settingsStorage;
  @override
  Future<DevStorage> get storage;
}

abstract class DevStorage = Storage with DevStorageCapability;

abstract class DevSettingsStorage = SettingsStorage
    with DevSettingsStorageCapability;

abstract class DevStorageCapability {
  Future<void> clear(String namespace);
  Future<void> showStats(String namespace);
}

abstract class DevSettingsStorageCapability {
  Future<void> clear();
}
