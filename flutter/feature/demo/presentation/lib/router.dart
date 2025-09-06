import 'package:auto_route/auto_route.dart';

import 'router.gr.dart';

@AutoRouterConfig(replaceInRouteName: DemoRouter._replaceRouteName)
final class DemoRouter extends RootStackRouter {
  static const String _replaceRouteName = 'View,Route';

  @override
  RouteType get defaultRouteType => const RouteType.material(
    enablePredictiveBackGesture: false,
  );

  @override
  List<AutoRoute> get routes {
    return [
      AutoRoute(
        page: FirstRoute.page,
        initial: true,
      ),
    ];
  }
}
