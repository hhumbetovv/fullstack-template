import 'package:auto_route/auto_route.dart';
import 'package:console_presentation/router.dart';
import 'package:core_navigation/public.dart';
import 'package:demo_presentation/router.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

@Singleton(as: RootStackRouter)
final class AppRouter extends ApplicationRouter {
  static RootStackRouter get instance => GetIt.I<RootStackRouter>();

  @override
  List<BaseRouter> get routers {
    return [
      DemoRouter(),
      ConsoleRouter(),
    ];
  }
}
