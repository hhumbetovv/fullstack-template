import 'package:auto_route/auto_route.dart';
import 'package:demo_presentation/router.dart';
import 'package:injectable/injectable.dart';

@Singleton()
@AutoRouterConfig(replaceInRouteName: AppRouter._replaceRouteName)
final class AppRouter extends RootStackRouter {
  static const String _replaceRouteName = 'View,Route';

  @override
  RouteType get defaultRouteType => const RouteType.material(
    enablePredictiveBackGesture: false,
  );

  @override
  List<AutoRoute> get routes {
    return [
      ...DemoRouter().routes,
    ];
  }
}
