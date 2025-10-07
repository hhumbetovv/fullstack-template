import 'package:auto_route/auto_route.dart';

abstract class BaseRouter {
  final List<BaseRouter> routers = [];

  List<AutoRoute> get routes => routers.routes;
}

extension RouterListX on List<BaseRouter> {
  List<AutoRoute> get routes {
    return fold([], (value, element) {
      return [...element.routes, ...value];
    });
  }
}
