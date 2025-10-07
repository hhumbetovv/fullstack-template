import 'package:auto_route/auto_route.dart';
import 'package:core_navigation/public.dart';
import 'package:demo_presentation/src/first/view.dart';

final class DemoRouter extends BaseRouter {
  @override
  List<AutoRoute> get routes {
    return [
      FeatureRoute(
        name: Routes.first,
        initial: true,
        builder: (context, data) {
          return const FirstView();
        },
      ),
    ];
  }
}
