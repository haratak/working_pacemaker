import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../platform.dart' show SettingsStorage;

class SettingsStorageImpl implements SettingsStorage {
  @protected
  final SharedPreferences preferences;

  @protected
  SettingsStorageImpl(this.preferences);

  static Future<SettingsStorage> initialize() async =>
      SettingsStorageImpl(await SharedPreferences.getInstance());

  Future<bool> setInt(String key, int value) => preferences.setInt(key, value);
  int getInt(String key) => preferences.getInt(key);
}
