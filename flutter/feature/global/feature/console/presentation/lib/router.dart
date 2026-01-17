import 'package:auto_route/auto_route.dart';
import 'package:console_presentation/src/console/view.dart';
import 'package:core_navigation/public.dart';

final class ConsoleRouter extends BaseRouter {
  @override
  List<AutoRoute> get routes {
    return [
      FeatureRoute(
        name: Routes.console,
        builder: (context, data) {
          return const ConsoleView();
        },
      ),
    ];
  }
}
