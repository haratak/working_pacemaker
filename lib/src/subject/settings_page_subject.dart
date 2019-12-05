import 'package:meta/meta.dart';
import 'package:working_pacemaker/src/localization/messages.dart';
import 'package:working_pacemaker/src/model/settings.dart';

@immutable
class SettingsPageSubject {
  final PacemakerSettings _pacemakerSettings;
  final AppMessages _messages;

  SettingsPageSubject(
      {@required PacemakerSettings pacemakerSettings,
      @required AppMessages messages})
      : assert(pacemakerSettings != null),
        assert(messages != null),
        _pacemakerSettings = pacemakerSettings,
        _messages = messages;

  Stream<Duration> get workingDurations =>
      _pacemakerSettings.notifier.workingDurations;
  Stream<Duration> get breakingDurations =>
      _pacemakerSettings.notifier.breakingDurations;

  List<DurationOptionView> get workingDurationOptions =>
      _pacemakerSettings.workingDurationOptions
          .map((e) => DurationOptionView(e, _messages.minutes))
          .toList();

  List<DurationOptionView> get breakingDurationOptions =>
      _pacemakerSettings.breakingDurationOptions
          .map((e) => DurationOptionView(e, _messages.minutes))
          .toList();

  void changeWorkingDuration(Duration duration) =>
      _pacemakerSettings.changeWorkingDuration(duration);

  void changeBreakingDuration(Duration duration) =>
      _pacemakerSettings.changeBreakingDuration(duration);
}

class DurationOptionView {
  final String text;
  final Duration value;
  DurationOptionView(this.value, String Function(int minutes) localize)
      : text = _durationToMinutesText(value, localize);

  static String _durationToMinutesText(
          Duration duration, String Function(int minutes) localize) =>
      localize(duration.inMinutes);
}
