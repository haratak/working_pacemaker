import 'dart:async';

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:working_pacemaker/src/localization/localization.dart';
import 'package:working_pacemaker/src/model/pacemaker/enums.dart';
import 'package:working_pacemaker/src/subject/timer_face_subject.dart';

import '../widget_key_values.dart' show timerFace;

/// TimerFace.
///
/// This displays phase and time.
/// Also this functions as button for start, pause, and resume.
/// Reset button appears inside this only on pause.
class TimerFace extends StatelessWidget {
  Widget build(BuildContext context) {
    final subject = Provider.of<TimerFaceSubject>(context);
    final themeData = Theme.of(context);
    // Cache it here to avoid rebuilding it on every update of the percents.
    final body = _TimerFaceBody(subject, themeData);

    return RawMaterialButton(
      key: Key(timerFace.timerFaceButton),
      onPressed: () => subject.onTimerFacePressed.add(null),
      shape: const CircleBorder(),
      child: StreamBuilder<double>(
        stream: subject.percents,
        initialData: 0.0,
        builder: (context, snapshot) {
          // The radius is actually diameter.
          // https://github.com/diegoveloper/flutter_percent_indicator/issues/33
          return CircularPercentIndicator(
            radius: 250,
            lineWidth: 3.0,
            percent: snapshot.data,
            progressColor: themeData.primaryColor,
            backgroundColor: themeData.accentColor,
            center: body,
          );
        },
      ),
    );
  }
}

class _TimerFaceBody extends StatelessWidget {
  final TimerFaceSubject _subject;
  final ThemeData _themeData;
  final TextStyle _phaseTextStyle;
  final TextStyle _timeTextStyle;
  _TimerFaceBody(this._subject, this._themeData)
      : _phaseTextStyle = TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _themeData.primaryColor),
        _timeTextStyle =
            TextStyle(fontSize: 64.0, color: _themeData.primaryColor);

  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: StreamBuilder<Tuple2<String, Phase>>(
              stream: _subject.phases,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text('', style: _phaseTextStyle);
                }

                return Text(
                  snapshot.data.item1,
                  key: Key(snapshot.data.item2 == Phase.working
                      ? timerFace.workingPhaseText
                      : timerFace.breakingPhaseText),
                  style: _phaseTextStyle,
                );
              },
            ),
          ),
        ),
        Container(
          child: StreamBuilder<Tuple2<String, bool>>(
            stream: _subject.timesAndIsTimerPaused,
            initialData: const Tuple2(null, false),
            builder: (context, snapshot) {
              final time = snapshot.data.item1;
              final isPaused = snapshot.data.item2;
              if (time == null) return Container();
              return isPaused
                  ? BlinkingText(
                      time,
                      textStyle: _timeTextStyle,
                      key: Key(timerFace.blinkingTimeText),
                    )
                  : Text(
                      time,
                      key: Key(timerFace.timeText),
                      style: _timeTextStyle,
                    );
            },
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: StreamBuilder<bool>(
              stream: _subject.canShowResetButton,
              initialData: false,
              builder: (context, snapshot) {
                return snapshot.data
                    ? MaterialButton(
                        key: Key(timerFace.resetButton),
                        onPressed: () =>
                            _subject.onResetButtonPressed.add(null),
                        child: Text(
                          l(context).reset,
                          style: TextStyle(
                              fontSize: 20,
                              color: _themeData.primaryColor,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    : Container();
              },
            ),
          ),
        )
      ],
    );
  }
}

@visibleForTesting
class BlinkingText extends StatefulWidget {
  final String _target;
  final Key _key;
  final TextStyle _textStyle;

  BlinkingText(this._target, {Key key, @required TextStyle textStyle})
      : assert(textStyle != null),
        _key = key,
        _textStyle = textStyle;

  _BlinkingTextState createState() =>
      _BlinkingTextState(_target, _textStyle, _key);
}

class _BlinkingTextState extends State<BlinkingText> {
  final Text _showingText;
  final Text _hidingText;
  Text _currentText;
  Timer _timer;

  _BlinkingTextState(String target, TextStyle textStyle, Key key)
      : _showingText = Text(target, key: key, style: textStyle),
        _hidingText = Text(target,
            key: key, style: textStyle.copyWith(color: Colors.transparent));

  void initState() {
    _currentText = _showingText;

    _timer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      setState(() {
        _currentText =
            _currentText == _showingText ? _hidingText : _showingText;
      });
    });

    super.initState();
  }

  Widget build(BuildContext context) => _currentText;

  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
