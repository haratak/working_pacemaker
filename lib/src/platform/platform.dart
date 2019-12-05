library platform;

import 'package:meta/meta.dart';
import 'package:working_pacemaker/src/flavor_config/flavor_config.dart';

/// Container of platform dependent module initializers.
///
/// All platform dependent modules must be resolved
/// in each platform implementation.
///
/// The initializers should lazily initialize their module,
/// for the sake of app launch speed.
///
/// The initializers should not be responsible for their module caching.
@immutable
abstract class Platform {
  Future<SettingsStorage> get settingsStorage;
  Future<Storage> get storage;
  Future<Sound> soundOf(Uri soundDataPath);
  Future<Analytics> analytics(
      {@required Flavor flavor, @required String appTitle});
}

@immutable
abstract class Analytics {
  @protected
  final String appTitle;

  Analytics(this.appTitle);

  dynamic get navigatorObserver;

  Future<void> logAppOpen();

  /// If [screenClassOverride] is null, subclass must set [appTitle] to it.
  /// If null, 'Flutter' is set by the framework, which is not as intended.
  Future<void> setCurrentScreen(
      {@required String screenName, String screenClassOverride});

  Future<void> logEvent(
      {@required String name, Map<String, dynamic> parameters});
}

abstract class Sound {
  Future<void> play();
  Future<void> dispose();
}

@immutable
abstract class SettingsStorage {
  Future<bool> setInt(String key, int value);
  int getInt(String key);
}

@immutable
abstract class Storage {
  // Nullable, if not found.
  Future<String> get(String key, {String namespace});
  Future<bool> exists(String key, {String namespace});
  Future<bool> set(String key, String value, {String namespace});
  Future<List<String>> listKeys({String namespace});
  Future<bool> delete(String key, {String namespace});
}
