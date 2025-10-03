import 'package:app/router/router.dart';
import 'package:common_presentation/public.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:ui_foundation/public.dart';

final router = GetIt.I<AppRouter>();

final class App extends StatelessWidget {
  const App({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
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
      // builder: (context, child) {
      //   return RootView(child: child ?? const SizedBox.shrink());
      // },
      themeAnimationCurve: const AppCurves.fastInFastOut(),
      routerConfig: router.config(
        navigatorObservers: () => [
          // if (Console.isEnabled) RouteLogger(),
          HeroController(),
        ],
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
