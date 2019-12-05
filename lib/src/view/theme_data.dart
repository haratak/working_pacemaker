import 'package:flutter/material.dart';

ThemeData get appThemeData => ThemeData(
    primarySwatch: Colors.indigo,
    primaryColor: _workingColor,
    accentColor: Colors.pinkAccent[700],
    buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
    brightness: Brightness.light,
    splashFactory: InkRipple.splashFactory,
    bottomAppBarTheme: _bottomAppBarTheme.copyWith(color: Colors.transparent));

PhaseThemeData get workingPhaseThemeData => PhaseThemeData(
        materialThemeData: appThemeData.copyWith(
          primaryColor: Colors.white,
          accentColor: Colors.indigo[100],
          bottomAppBarTheme:
              _bottomAppBarTheme.copyWith(color: Colors.transparent),
          iconTheme: IconThemeData(color: Colors.white),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
              foregroundColor: _workingColor, backgroundColor: Colors.white),
        ),
        backgroundGradientColors: [
          Colors.indigo[300],
          Colors.indigo[800],
        ]);

// TODO: change to nicer color theme.
PhaseThemeData get breakingPhaseThemeData => PhaseThemeData(
        materialThemeData: appThemeData.copyWith(
          bottomAppBarTheme: _bottomAppBarTheme.copyWith(color: _breakingColor),
          primaryColor: _breakingTextColor,
          accentColor: Colors.brown[200],
          textTheme:
              Typography.whiteMountainView.apply(bodyColor: _breakingTextColor),
          iconTheme: IconThemeData(color: _breakingTextColor),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
              foregroundColor: _breakingColor,
              backgroundColor: _breakingTextColor),
          scaffoldBackgroundColor: _breakingColor,
        ),
        backgroundGradientColors: [
          Colors.brown[100],
          _breakingColor,
        ]);

class PhaseThemeData {
  final ThemeData materialThemeData;
  final List<Color> backgroundGradientColors;
  PhaseThemeData(
      {@required this.materialThemeData,
      @required this.backgroundGradientColors});
}

get _bottomAppBarTheme =>
    const BottomAppBarTheme(elevation: 0, shape: CircularNotchedRectangle());

get _workingColor => Colors.indigo[600];
get _breakingColor => Colors.brown[200];
get _breakingTextColor => Colors.grey[700];
