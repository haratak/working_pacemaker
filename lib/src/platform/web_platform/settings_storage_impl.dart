import '../platform.dart' show SettingsStorage;
import 'local_storage.dart';

class SettingsStorageImpl with LocalStorage implements SettingsStorage {
  final String namespace = 'settings';

  Future<bool> setInt(String key, int value) async {
    setValue(keyWithNamespace(key, namespace), value.toString());
    return true;
  }

  int getInt(String key) {
    final value = getValue(keyWithNamespace(key, namespace));
    if (value == null) return null;
    return int.tryParse(value);
  }
}
