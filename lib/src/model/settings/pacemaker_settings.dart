import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:working_pacemaker/src/model/settings/analytics_logger.dart';
import 'package:working_pacemaker/src/platform/platform.dart' as platform;

class PacemakerSettings {
  final ChangeNotifier notifier = ChangeNotifier();
  final _SettingsStorage _storage;
  final DefaultSettings _defaultSettings;
  final AnalyticsLogger _logger;

  PacemakerSettings._(this._storage, this._defaultSettings, this._logger) {
    _notifySettingsFromStorage();
  }

  static Future<PacemakerSettings> initialize({
    @required platform.SettingsStorage settingsStorage,
    @required DefaultSettings defaultSettings,
    @required platform.Analytics analytics,
  }) async {
    assert(settingsStorage != null);
    assert(defaultSettings != null);
    assert(analytics != null);
    final storage = _SettingsStorage(settingsStorage, defaultSettings);
    await storage.initializeEachSettingIfNullWithCorrespondingDefault();
    return PacemakerSettings._(
        storage, defaultSettings, AnalyticsLogger(analytics));
  }

  List<Duration> get workingDurationOptions =>
      _defaultSettings.workingDurationOptions;
  List<Duration> get breakingDurationOptions =>
      _defaultSettings.breakingDurationOptions;

  Future<bool> changeWorkingDuration(Duration value) async {
    final isSuccess = await _storage.setWorkingDuration(value);
    if (isSuccess) {
      notifier.workingDurationsController.add(value);
      _logger.logWorkingDurationChanged(value);
    }
    return isSuccess;
  }

  Future<bool> changeBreakingDuration(Duration value) async {
    final isSuccess = await _storage.setBreakingDuration(value);
    if (isSuccess) {
      notifier.breakingDurationsController.add(value);
      _logger.logBreakingDurationChanged(value);
    }
    return isSuccess;
  }

  void dispose() {
    notifier.dispose();
  }

  void _notifySettingsFromStorage() {
    notifier.workingDurationsController.add(_storage.workingDuration);
    notifier.breakingDurationsController.add(_storage.breakingDuration);
  }
}

class ChangeNotifier {
  @visibleForTesting
  final workingDurationsController = BehaviorSubject<Duration>();
  @visibleForTesting
  final breakingDurationsController = BehaviorSubject<Duration>();

  Stream<Duration> get workingDurations => workingDurationsController.stream;
  Stream<Duration> get breakingDurations => breakingDurationsController.stream;

  @visibleForTesting
  void dispose() {
    workingDurationsController.close();
    breakingDurationsController.close();
  }
}

const maxWorkingDuration = Duration(minutes: 90);
const minWorkingDuration = Duration(minutes: 10);
const maxBreakingDuration = Duration(minutes: 60);
const minBreakingDuration = Duration(minutes: 5);

@immutable
abstract class DefaultSettings {
  List<Duration> get workingDurationOptions;
  List<Duration> get breakingDurationOptions;
  Duration get workingDuration;
  Duration get breakingDuration;

  DefaultSettings() {
    assert(workingDurationOptions.contains(workingDuration));
    assert(breakingDurationOptions.contains(breakingDuration));
  }
}

@visibleForTesting
class SettingsStorageKeys {
  static const namespace = 'pacemaker';
  static const workingDurationInSeconds =
      '${namespace}_working_duration_in_seconds';
  static const breakingDurationInSeconds =
      '${namespace}_breaking_duration_in_seconds';
}

class _SettingsStorage {
  final platform.SettingsStorage _storage;
  final DefaultSettings _defaultSettings;

  _SettingsStorage(this._storage, this._defaultSettings)
      : assert(_storage != null),
        assert(_defaultSettings != null);

  Duration get workingDuration {
    final seconds =
        _storage.getInt(SettingsStorageKeys.workingDurationInSeconds);
    assert(seconds != null);
    return Duration(seconds: seconds);
  }

  Duration get breakingDuration {
    final seconds =
        _storage.getInt(SettingsStorageKeys.breakingDurationInSeconds);
    assert(seconds != null);
    return Duration(seconds: seconds);
  }

  Future<bool> setWorkingDuration(Duration value) async {
    assert(value != null);
    return _storage.setInt(
        SettingsStorageKeys.workingDurationInSeconds, value.inSeconds);
  }

  Future<bool> setBreakingDuration(Duration value) async {
    assert(value != null);
    return _storage.setInt(
        SettingsStorageKeys.breakingDurationInSeconds, value.inSeconds);
  }

  Future<void> initializeEachSettingIfNullWithCorrespondingDefault() async {
    if (_storage.getInt(SettingsStorageKeys.workingDurationInSeconds) == null) {
      await setWorkingDuration(_defaultSettings.workingDuration);
    }

    if (_storage.getInt(SettingsStorageKeys.breakingDurationInSeconds) ==
        null) {
      await setBreakingDuration(_defaultSettings.breakingDuration);
    }
  }
}
