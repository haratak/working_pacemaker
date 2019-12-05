import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:working_pacemaker/src/platform/platform.dart';

import '../performance_logging.dart';
import 'data.dart';

abstract class PerformanceLogRepository {
  @protected
  final namespace = 'performance_log';

  @protected
  Storage get storage;

  @protected
  String keyOfMonth(DateTime month) => '${month.year}_${month.month}';

  @protected
  DateTime keyToMonth(String key) {
    final s = key.split('_');
    return DateTime(int.parse(s.first), int.parse(s.last));
  }

  Future<List<PerformanceLog>> listOfMonth(DateTime month) {
    return storage
        .get(keyOfMonth(month), namespace: namespace)
        .then(deserialize);
  }

  @protected
  String serialize(List<PerformanceLog> performanceLogs) {
    return jsonEncode(performanceLogs.map((log) => log.toJson()).toList());
  }

  @protected
  List<PerformanceLog> deserialize(String serializedData) {
    if (serializedData == null) return [];

    final List<dynamic> jsonList = jsonDecode(serializedData);
    return jsonList.map((j) => PerformanceLog.fromJson(j)).toList();
  }
}
