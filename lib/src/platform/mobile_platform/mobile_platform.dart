import 'package:meta/meta.dart';
import 'package:working_pacemaker/src/flavor_config/flavor_config.dart';
import 'package:working_pacemaker/src/platform/platform.dart';

import 'analytics_impl.dart';
import 'settings_storage_impl.dart';
import 'sound_impl.dart';
import 'storage_impl.dart';

const mobilePlatform = MobilePlatform();

/// Platform for iOS and Android native environment.
///
/// If dedicated modules for iOS or Android are required,
/// define IosPlatform and AndroidPlatform respectively.
class MobilePlatform implements Platform {
  const MobilePlatform();

  Future<SettingsStorage> get settingsStorage =>
      SettingsStorageImpl.initialize();

  Future<Storage> get storage => Future.value(StorageImpl());

  Future<Sound> soundOf(Uri soundDataPath) async =>
      SoundImpl(soundDataPath: soundDataPath);

  Future<Analytics> analytics(
          {@required Flavor flavor, @required String appTitle}) =>
      initializeAnalytics(flavor: flavor, appTitle: appTitle);
}
