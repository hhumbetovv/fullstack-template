import 'package:auto_route/auto_route.dart';
import 'package:core_navigation/src/core/base_router.dart';
import 'package:flutter/foundation.dart';

abstract class ApplicationRouter extends RootStackRouter implements BaseRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material(
    enablePredictiveBackGesture: false,
  );

  @override
  List<BaseRouter> get routers => [];

  @override
  @mustCallSuper
  List<AutoRoute> get routes => routers.routes;
}
