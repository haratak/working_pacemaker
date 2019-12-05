import 'package:flutter/cupertino.dart';

import '../platform.dart';
import 'local_storage.dart';

class StorageImpl with LocalStorage implements Storage {
  Future<String> get(String key, {@required String namespace}) {
    assert(namespace != null);
    return Future.value(getValue(keyWithNamespace(key, namespace)));
  }

  Future<bool> exists(String key, {@required String namespace}) async {
    assert(namespace != null);
    return (await get(key, namespace: namespace)) != null;
  }

  Future<bool> set(String key, String value, {@required String namespace}) {
    assert(namespace != null);
    setValue(keyWithNamespace(key, namespace), value);
    return Future.value(true);
  }

  Future<List<String>> listKeys({@required String namespace}) {
    assert(namespace != null);
    return Future.value(localStorage.keys
        .where((key) => key.startsWith(keyWithNamespace(namespace)))
        .toList());
  }

  Future<bool> delete(String key, {@required String namespace}) {
    assert(namespace != null);
    final result = localStorage.remove(keyWithNamespace(key, namespace));
    return Future.value(result != null);
  }
}
