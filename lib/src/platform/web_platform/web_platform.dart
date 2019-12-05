import 'package:meta/meta.dart';
import 'package:working_pacemaker/src/flavor_config/flavor_config.dart';
import 'package:working_pacemaker/src/platform/platform.dart';

import 'analytics_impl.dart';
import 'settings_storage_impl.dart';
import 'sound_impl.dart';
import 'storage_impl.dart';

const webPlatform = _WebPlatform();

/// Platform for Web.
class _WebPlatform implements Platform {
  const _WebPlatform();

  Future<SettingsStorage> get settingsStorage =>
      Future.value(SettingsStorageImpl());

  Future<Storage> get storage => Future.value(StorageImpl());

  Future<Sound> soundOf(Uri soundDataPath) =>
      Future.value(SoundImpl(soundDataPath: soundDataPath));

  Future<Analytics> analytics(
          {@required Flavor flavor, @required String appTitle}) =>
      Future.value(AnalyticsImpl(appTitle));
}
