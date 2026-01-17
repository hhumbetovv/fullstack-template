import 'package:auto_route/auto_route.dart';
import 'package:common_shared/public.dart';
import 'package:flutter/widgets.dart';

final class RouteLogger extends AutoRouterObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    Console.log(
      '🧭 NAVIGATION | PUSH\n'
          'PREVIOUS: ${previousRoute?.settings.name}\n'
          'PUSHED: ${route.settings.name}\n',
      AnsiColors.orange,
      'Navigation',
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    Console.log(
      '🧭 NAVIGATION | POP\n'
          'POPPED: ${route.settings.name}\n'
          'BACK TO: ${previousRoute?.settings.name}\n',
      AnsiColors.orange,
      'Navigation',
    );
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    Console.log(
      '🧭 NAVIGATION | REPLACE\n'
          'OLD ROUTE: ${oldRoute?.settings.name}\n'
          'NEW ROUTE: ${newRoute?.settings.name}\n',
      AnsiColors.orange,
      'Navigation',
    );
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    Console.log(
      '🧭 NAVIGATION | REMOVE\n'
          'ROUTE: ${route.settings.name}\n',
      AnsiColors.orange,
      'Navigation',
    );
  }
}
