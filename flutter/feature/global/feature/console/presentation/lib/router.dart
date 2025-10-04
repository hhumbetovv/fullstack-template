import 'package:auto_route/auto_route.dart';
import 'package:core_presentation/exports.dart';

import 'router.gr.dart';

@AutoRouterConfig(replaceInRouteName: BaseRouter.replaceInName)
final class ConsoleRouter extends BaseRouter {
  @override
  List<AutoRoute> get routes {
    return [
      FeatureRoute(
        page: ConsoleRoute.page,
      ),
    ];
  }
}
