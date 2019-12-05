import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:working_pacemaker/src/localization/localization.dart';
import 'package:working_pacemaker/src/subject/settings_page_subject.dart';

import 'widget_key_values.dart';

class SettingsPage extends StatelessWidget {
  Widget build(BuildContext context) {
    final subject = Provider.of<SettingsPageSubject>(context);

    return Scaffold(
      appBar: AppBar(title: Text(l(context).settings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(54, 16, 16, 16),
          children: <Widget>[
            StreamBuilder<Duration>(
              stream: subject.workingDurations,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Container();
                return ListTile(
                  title: Text(l(context).workingDuration),
                  subtitle: Text(
                    l(context).minutes(snapshot.data.inMinutes),
                    key: Key(settingsPage.workingDurationText),
                  ),
                  onTap: () => _showDurationOptionsDialog(context,
                      dialogTitle: l(context)
                          .selectDurationOf(l(context).workingDuration),
                      selectedDurations: subject.workingDurations,
                      options: subject.workingDurationOptions,
                      onChanged: subject.changeWorkingDuration),
                );
              },
            ),
            StreamBuilder<Duration>(
              stream: subject.breakingDurations,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Container();
                return ListTile(
                  title: Text(l(context).breakingDuration),
                  subtitle: Text(
                    l(context).minutes(snapshot.data.inMinutes),
                    key: Key(settingsPage.breakingDurationText),
                  ),
                  onTap: () => _showDurationOptionsDialog(context,
                      dialogTitle: l(context)
                          .selectDurationOf(l(context).breakingDuration),
                      selectedDurations: subject.breakingDurations,
                      options: subject.breakingDurationOptions,
                      onChanged: subject.changeBreakingDuration),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDurationOptionsDialog(BuildContext context,
      {@required String dialogTitle,
      @required Stream<Duration> selectedDurations,
      @required List<DurationOptionView> options,
      @required void onChanged(Duration value)}) {
    final dialogCloseDelay = const Duration(milliseconds: 500);
    return showDialog<Duration>(
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<Duration>(
          stream: selectedDurations,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Container();
            return SimpleDialog(
                key: Key(settingsPage.durationSelectDialog),
                title: Text(dialogTitle),
                children: options.map((option) {
                  return RadioListTile<Duration>(
                      title: Text(option.text),
                      value: option.value,
                      groupValue: snapshot.data,
                      onChanged: (Duration value) async {
                        onChanged(value);
                        Future.delayed(
                            dialogCloseDelay, () => Navigator.pop(context));
                      });
                }).toList());
          },
        );
      },
    );
  }
}
