import 'package:app/app/root.dart';
import 'package:app/navigation/entry_provider.dart';
import 'package:app/navigation/route_logger.dart';
import 'package:common_presentation/public.dart';
import 'package:common_shared/public.dart';
import 'package:core_navigation/public.dart';
import 'package:flutter/material.dart';
import 'package:ui_foundation/public.dart';

final class App extends StatelessWidget {
  const App({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final navigatorObservers = <NavigatorObserver>[
      if (Console.isEnabled) RouteLogger(),
      HeroController(),
    ];
    return MaterialApp(
      title: 'Template',
      scaffoldMessengerKey: messengerKey,
      key: applicationKey,
      // theme: BaseTheme.light,
      // darkTheme: BaseTheme.dark,
      // locale: prefsSelect(context, (state) => state.locale),
      // localizationsDelegates: const [
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalCupertinoLocalizations.delegate,
      // ],
      // supportedLocales: prefsSelect(context, (state) => state.supportedLocales),
      // themeMode: prefsSelect(context, (state) => state.themeMode),
      scrollBehavior: AppScrollBehavior().copyWith(
        physics: AppDefaults.scrollPhysics,
      ),
      themeAnimationCurve: const AppCurves.fastInFastOut(),
      home: RootView(
        child: NavDisplay(
          entryProvider: (provider) {
            provider.include(AppEntryProvider());
          },
          observers: navigatorObservers,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
