import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:working_pacemaker/src/flavor_config/production_config.dart';
import 'package:working_pacemaker/src/model/settings.dart';
import 'package:working_pacemaker/src/model/settings/pacemaker_settings.dart';
import 'package:working_pacemaker/src/platform/platform.dart' as platform
    show SettingsStorage;
import 'package:working_pacemaker/src/platform/platform.dart';

class FakeSettingsStorage extends Fake implements platform.SettingsStorage {
  final Map<String, dynamic> _storage = {};
  Future<bool> setInt(String key, int value) async {
    _storage[key] = value;
    return true;
  }

  int getInt(String key) {
    return _storage[key];
  }

  void clear() {
    _storage.clear();
  }
}

// ignore: must_be_immutable
class MockAnalytics extends Mock implements Analytics {}

void main() {
  group(PacemakerSettings, () {
    final defaultPacemakerSettings = ProductionPacemakerDefaultSettings();
    Duration workingDuration;
    Duration breakingDuration;
    platform.SettingsStorage storage;
    PacemakerSettings settings;
    MockAnalytics mockAnalytics;

    setUp(() async {
      workingDuration = defaultPacemakerSettings.workingDuration;
      breakingDuration = defaultPacemakerSettings.breakingDuration;
      storage = FakeSettingsStorage();
      mockAnalytics = MockAnalytics();

      settings = await PacemakerSettings.initialize(
          settingsStorage: storage,
          defaultSettings: defaultPacemakerSettings,
          analytics: mockAnalytics);
    });

    test('Storage Keys.', () {
      expect(SettingsStorageKeys.workingDurationInSeconds,
          'pacemaker_working_duration_in_seconds');
      expect(SettingsStorageKeys.breakingDurationInSeconds,
          'pacemaker_breaking_duration_in_seconds');
    });

    group('Initialize.', () {
      group('When each storage value is null.', () {
        setUp(() async {
          (storage as FakeSettingsStorage).clear();
          settings = await PacemakerSettings.initialize(
              settingsStorage: storage,
              defaultSettings: defaultPacemakerSettings,
              analytics: MockAnalytics());
        });

        test('Initialize each value with corresponding default value.',
            () async {
          expect(storage.getInt(SettingsStorageKeys.workingDurationInSeconds),
              defaultPacemakerSettings.workingDuration.inSeconds);
          expect(storage.getInt(SettingsStorageKeys.breakingDurationInSeconds),
              defaultPacemakerSettings.breakingDuration.inSeconds);
        });
      });

      group('When each storage value is not null.', () {
        Duration workingDuration;
        Duration breakingDuration;
        setUp(() async {
          workingDuration = const Duration(minutes: 25);
          breakingDuration = const Duration(minutes: 5);
          (storage as FakeSettingsStorage).clear();
          await storage.setInt(SettingsStorageKeys.workingDurationInSeconds,
              workingDuration.inSeconds);
          await storage.setInt(SettingsStorageKeys.breakingDurationInSeconds,
              breakingDuration.inSeconds);
          settings = await PacemakerSettings.initialize(
              settingsStorage: storage,
              defaultSettings: defaultPacemakerSettings,
              analytics: mockAnalytics);
        });

        test('Each value remains.', () {
          expect(storage.getInt(SettingsStorageKeys.workingDurationInSeconds),
              workingDuration.inSeconds);
          expect(storage.getInt(SettingsStorageKeys.breakingDurationInSeconds),
              breakingDuration.inSeconds);
        });
      });
    });

    test('Can notify settings on initialized.', () async {
      expect(settings.notifier.workingDurations, emits(workingDuration));
      expect(settings.notifier.breakingDurations, emits(breakingDuration));
    });

    test('Notify working duration on changed.', () async {
      final newDuration = const Duration(minutes: 25);
      assert(newDuration != workingDuration);

      await settings.changeWorkingDuration(newDuration);
      expect(storage.getInt(SettingsStorageKeys.workingDurationInSeconds),
          newDuration.inSeconds);
      expect(settings.notifier.workingDurations, emits(newDuration));
    });

    test('Notify breaking duration on changed.', () async {
      final newDuration = const Duration(minutes: 5);
      assert(newDuration != breakingDuration);

      await settings.changeBreakingDuration(newDuration);
      expect(storage.getInt(SettingsStorageKeys.breakingDurationInSeconds),
          newDuration.inSeconds);
      expect(settings.notifier.breakingDurations, emits(newDuration));
    });

    group('Analytics Logging', () {
      test('logWorkingDurationChanged.', () async {
        const minutes = 25;
        final newDuration = const Duration(minutes: minutes);
        assert(newDuration != workingDuration);

        await settings.changeWorkingDuration(newDuration);

        verify(mockAnalytics
            .logEvent(name: 'setting_of_working_duration_changed', parameters: {
          'minutes': minutes,
        })).called(1);
      });

      test('logBreakingDurationChanged.', () async {
        const minutes = 5;
        final newDuration = const Duration(minutes: minutes);
        assert(newDuration != breakingDuration);

        await settings.changeBreakingDuration(newDuration);

        verify(mockAnalytics.logEvent(
            name: 'setting_of_breaking_duration_changed',
            parameters: {
              'minutes': minutes,
            })).called(1);
      });
    });
  });
}
