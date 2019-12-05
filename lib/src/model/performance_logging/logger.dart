import 'dart:async';

import 'package:meta/meta.dart';
import 'package:working_pacemaker/src/model/performance_logging/analytics_logger.dart';
import 'package:working_pacemaker/src/platform/platform.dart';

import 'data.dart';
import 'repository.dart';

class Logger {
  // ignore: close_sinks
  final _controller = StreamController<Duration>();
  final _Repository _repository;
  final AnalyticsLogger _logger;

  Logger({@required Storage storage, @required Analytics analytics})
      : assert(storage != null),
        assert(analytics != null),
        _repository = _Repository(storage),
        _logger = AnalyticsLogger(analytics) {
    _controller.stream.listen(_log);
  }

  Sink<Duration> get onWorkingPhaseIsFinished => _controller.sink;

  @visibleForTesting
  DateTime get now => DateTime.now();

  void _log(Duration workingDuration) async {
    final log = PerformanceLog(now, workingDuration.inMinutes);
    final isSuccess = await _repository.put(log);
    if (isSuccess) {
      _logger.logPerformanceLogging(log);
    } else {
      _logger.logFailedPerformanceLogging(log);
    }
  }
}

class _Repository with PerformanceLogRepository {
  @protected
  final Storage storage;

  _Repository(this.storage);

  Future<bool> put(PerformanceLog log) async {
    final logs = await listOfMonth(log.finishedTime);
    logs.add(log);
    return storage.set(keyOfMonth(log.finishedTime), serialize(logs),
        namespace: namespace);
  }
}
