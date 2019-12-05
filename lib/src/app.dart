import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'flavor_config/flavor_config.dart';
import 'localization/app_localizations.dart';
import 'localization/localization.dart';
import 'localization/messages.dart';
import 'model/pacemaker.dart';
import 'model/performance_logging.dart' as performance_logging;
import 'model/performance_logging/log_deleter.dart';
import 'model/settings.dart';
import 'platform/platform.dart';
import 'subject/home_page_subject.dart';
import 'subject/performance_log_page_subject.dart';
import 'subject/settings_page_subject.dart';
import 'subject/timer_face_subject.dart';
import 'view/app_root_modules.dart';
import 'view/home_page.dart';
import 'view/performance_log_page.dart';
import 'view/route_names.dart';
import 'view/settings_page.dart';
import 'view/theme_data.dart';

class App extends StatelessWidget {
  final _appRootModulesInitializingCompleter = Completer<AppRootModules>();

  App({@required Platform platform, @required FlavorConfig config})
      : assert(platform != null),
        assert(config != null) {
    _AppRootModulesInitializer(platform: platform, config: config)
        .initialize()
        .then((appRootModules) {
      appRootModules.analytics.logAppOpen();
      return appRootModules;
    }).then((appRootModules) {
      _appRootModulesInitializingCompleter.complete(appRootModules);
      return appRootModules;
    }).then((appRootModules) {
      Future.delayed(
          const Duration(seconds: 5),
          () => LogDeleter(
                  storage: appRootModules.storage,
                  analytics: appRootModules.analytics)
              .deleteOldLogs());
    });
  }

  Widget build(BuildContext context) {
    return FutureBuilder<AppRootModules>(
      future: _appRootModulesInitializingCompleter.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container();
        }

        final appRootModules = snapshot.data;

        return Provider<AppRootModules>.value(
          value: appRootModules,
          child: MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: supportedLocales,
            navigatorObservers: appRootModules.navigatorObservers,
            title: appRootModules.config.appTitle,
            theme: appThemeData,
            routes: {
              RouteName.root: (context) {
                return MultiProvider(providers: [
                  ProxyProvider<AppRootModules, HomePageSubject>(
                    builder: (_, m, __) {
                      return HomePageSubject(
                          pacemaker: m.pacemaker, analytics: m.analytics);
                    },
                    dispose: (context, self) {
                      self.dispose();
                    },
                  ),
                  ProxyProvider<AppRootModules, TimerFaceSubject>(
                    builder: (_, m, __) {
                      return TimerFaceSubject(
                          pacemaker: m.pacemaker,
                          messages: AppMessages(locale(context)));
                    },
                    dispose: (context, self) {
                      self.dispose();
                    },
                  ),
                ], child: HomePage());
              },
              RouteName.settings: (context) {
                return Provider<SettingsPageSubject>(
                  builder: (_) {
                    final m = Provider.of<AppRootModules>(context);
                    return SettingsPageSubject(
                        pacemakerSettings: m.pacemakerSettings,
                        messages: AppMessages(locale(context)));
                  },
                  dispose: (context, self) {
                    // noop.
                  },
                  child: SettingsPage(),
                );
              },
              RouteName.performance_log: (context) {
                return Provider<PerformanceLogPageSubject>(
                  builder: (_) {
                    final m = Provider.of<AppRootModules>(context);
                    return PerformanceLogPageSubject(
                        performanceLogReader:
                            performance_logging.LogReader(storage: m.storage),
                        messages: AppMessages(locale(context)),
                        analytics: m.analytics);
                  },
                  dispose: (context, self) {
                    self.dispose();
                  },
                  child: PerformanceLogPage(),
                );
              },
            },
          ),
        );
      },
    );
  }
}

class _AppRootModulesInitializer {
  final Platform _platform;
  final FlavorConfig _config;
  _AppRootModulesInitializer(
      {@required Platform platform, @required FlavorConfig config})
      : _platform = platform,
        _config = config;

  Future<AppRootModules> initialize() async {
    final analytics = await _platform.analytics(
        flavor: _config.flavor, appTitle: _config.appTitle);

    final pacemakerSettings = await PacemakerSettings.initialize(
        settingsStorage: await _platform.settingsStorage,
        defaultSettings: _config.pacemakerDefaultSettings,
        analytics: analytics);

    const soundPathSegments = ['asset', 'audio', 'sound'];

    final sounds = Sounds(
        countdown: await _platform.soundOf(
            Uri(pathSegments: [...soundPathSegments, 'countdown.mp3'])),
        countZero: await _platform.soundOf(
            Uri(pathSegments: [...soundPathSegments, 'count_zero.mp3'])),
        paceMaking: await _platform.soundOf(
            Uri(pathSegments: [...soundPathSegments, 'pace_making.mp3'])));

    final pacemaker = await Pacemaker.initialize(
        notifier: pacemakerSettings.notifier,
        sounds: sounds,
        analytics: analytics);

    final storage = await _platform.storage;

    final performanceLogger =
        performance_logging.Logger(storage: storage, analytics: analytics);
    pacemaker.workingPhaseIsFinished
        .listen(performanceLogger.onWorkingPhaseIsFinished.add);

    final List<NavigatorObserver> _navigatorObservers =
        analytics.navigatorObserver != null
            ? [analytics.navigatorObserver]
            : [];

    final appRootModules = AppRootModules(
      platform: _platform,
      config: _config,
      analytics: analytics,
      storage: storage,
      navigatorObservers: _navigatorObservers,
      pacemaker: pacemaker,
      performanceLogger: performanceLogger,
      pacemakerSettings: pacemakerSettings,
    );

    return appRootModules;
  }
}
