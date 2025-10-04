import 'package:auto_route/auto_route.dart';
import 'package:core_presentation/exports.dart';
import 'package:demo_presentation/router.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

@Singleton(as: RootStackRouter)
@AutoRouterConfig(replaceInRouteName: BaseRouter.replaceInName)
final class AppRouter extends BaseRouter {
  static RootStackRouter get instance => GetIt.I<RootStackRouter>();

  @override
  List<AutoRoute> get routes {
    return [
      ...DemoRouter().routes,
    ];
  }
}
