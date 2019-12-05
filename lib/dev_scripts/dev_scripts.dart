import 'package:flutter/widgets.dart';
import 'package:working_pacemaker/dev_scripts/performance_log_data_set_generator.dart';
import 'package:working_pacemaker/src/model/performance_logging.dart';
import 'package:working_pacemaker/src/model/performance_logging/repository.dart';

import 'dev_platform.dart';

enum DataSetType { zero, typical, maximum }

class DevStorageInitializers {
  final DevPlatform _devPlatform;

  DevStorageInitializers(this._devPlatform) {
    WidgetsFlutterBinding.ensureInitialized();
  }

  Future<void> clearSettingsStorage() async {
    await (await _devPlatform.settingsStorage).clear();
  }

  Future<void> initializePerformanceLogStorage() async {
    // ---- Edit this enum for different data set. ---
    final dataSetType = DataSetType.typical;

    final storage = await _devPlatform.storage;
    await _PerformanceLogInitializer(storage).initializeWith(dataSetType);
  }
}

class _PerformanceLogInitializer {
  final DevPerformanceLogRepository _repository;
  final PerformanceLogDataSetGenerator _generator =
      PerformanceLogDataSetGenerator();
  _PerformanceLogInitializer(DevStorage storage)
      : _repository = DevPerformanceLogRepository(storage);

  Future initializeWith(DataSetType dataSetType) async {
    switch (dataSetType) {
      case DataSetType.typical:
        return _initializeWithTypicalDataSet();
      case DataSetType.maximum:
        return _initializeWithMaximumDataSet();
      case DataSetType.zero:
        return _clearDataSet();
    }
  }

  Future _clearDataSet() async {
    await _repository.clear();
    await _repository.showStats();
  }

  Future _initializeWithTypicalDataSet() async {
    await _repository.clear();

    final dataSet = _generator.typicalDataSet(DateTime.now(), untilNow: true);

    for (final data in dataSet) {
      await _repository.set(data.first.finishedTime, data);
    }

    await _repository.showStats();
  }

  Future _initializeWithMaximumDataSet() async {
    await _repository.clear();

    final dataSet = _generator.maximumDataSet(DateTime.now(), untilNow: true);

    for (final data in dataSet) {
      await _repository.set(data.first.finishedTime, data);
    }

    await _repository.showStats();
  }
}

class DevPerformanceLogRepository with PerformanceLogRepository {
  @protected
  final DevStorage storage;

  DevPerformanceLogRepository(this.storage);

  Future<void> set(DateTime dateTime, List<PerformanceLog> logs) async {
    await storage.set(keyOfMonth(dateTime), serialize(logs),
        namespace: namespace);
  }

  Future<void> clear() async {
    await storage.clear(namespace);
  }

  Future<void> showStats() async {
    await storage.showStats(namespace);
  }
}
