import 'package:auto_route/auto_route.dart';

abstract class BaseRouter extends RootStackRouter {
  static const replaceInName = 'View,Route';

  @override
  RouteType get defaultRouteType => const RouteType.material(
    enablePredictiveBackGesture: false,
  );
}
