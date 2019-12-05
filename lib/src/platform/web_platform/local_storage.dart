import 'dart:html' as dom;

import 'package:meta/meta.dart';

mixin LocalStorage {
  @protected
  final dom.Storage localStorage = dom.window.localStorage;

  final String _appNamespace = 'app';

  @protected
  String keyWithNamespace(String key, [String namespace]) {
    final segments = [_appNamespace, key];
    if (namespace != null && namespace.isNotEmpty) {
      segments.insert(1, namespace);
    }
    return Uri(pathSegments: segments).toString();
  }

  @protected
  String getValue(String key) => localStorage[key];

  @protected
  void setValue(String key, String value) => localStorage[key] = value;
}
