import 'package:auto_route/auto_route.dart';

final class InstantRoute extends NamedRouteDef {
  InstantRoute({
    required super.name,
    required super.builder,
    super.children,
    super.initial,
    super.path,
    super.guards,
    super.keepHistory,
  }) : super(
         type: RouteType.custom(
           duration: Duration.zero,
           reverseDuration: Duration.zero,
           transitionsBuilder: (context, animation, secondaryAnimation, child) {
             return child;
           },
         ),
       );
}
