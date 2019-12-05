import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:working_pacemaker/src/subject/home_page_subject.dart';

import 'home_page/timer_face.dart';
import 'route_names.dart';
import 'theme_data.dart';
import 'widget_key_values.dart';

class HomePage extends StatelessWidget {
  Widget build(BuildContext context) {
    final subject = Provider.of<HomePageSubject>(context);

    return SafeArea(
      child: StreamBuilder<PhaseThemeData>(
        stream: subject.phaseThemeData,
        initialData: workingPhaseThemeData,
        builder: (context, snapshot) {
          final phaseThemeData = snapshot.data;
          return Theme(
            data: phaseThemeData.materialThemeData,
            child: Scaffold(
              body: StreamBuilder<double>(
                stream: subject.backgroundGradientYLerp,
                initialData: -1.0,
                builder: (context, snapshot) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.lerp(Alignment.bottomCenter,
                            Alignment.topCenter, snapshot.data),
                        end: Alignment.bottomCenter,
                        colors: phaseThemeData.backgroundGradientColors,
                      ),
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        child: TimerFace(),
                      ),
                    ),
                  );
                },
              ),
              extendBody: true,
              bottomNavigationBar: BottomAppBar(
                color: Colors.transparent,
                notchMargin: 4.0,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    IconButton(
                      key: Key(homePage.showChartButton),
                      icon: Icon(Icons.show_chart),
                      onPressed: () {
                        Navigator.pushNamed(context, RouteName.performance_log);
                      },
                    ),
                    IconButton(
                      key: Key(homePage.settingsButton),
                      icon: Icon(Icons.settings),
                      onPressed: () {
                        Navigator.pushNamed(context, RouteName.settings);
                      },
                    ),
                  ],
                ),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
              floatingActionButton: StreamBuilder<bool>(
                stream: subject.isTimerRunning,
                initialData: false,
                builder: (context, snapshot) {
                  return FloatingActionButton(
                      key: Key(homePage.floatingActionButton),
                      child:
                          Icon(snapshot.data ? Icons.pause : Icons.play_arrow),
                      onPressed: () => subject.onFabPressed.add(null));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
