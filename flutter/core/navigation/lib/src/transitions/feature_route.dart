import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class FeatureRoute extends NamedRouteDef {
  FeatureRoute({
    required super.name,
    required super.builder,
    super.children,
    super.initial,
    super.path,
    super.guards,
    super.keepHistory,
  }) : super(
         type: RouteType.custom(
           customRouteBuilder: materialRoute,
           enablePredictiveBackGesture: false,
         ),
       );
}

Route<T> materialRoute<T>(
  BuildContext context,
  Widget child,
  AutoRoutePage<void> page,
) {
  return MaterialPageRoute(
    settings: page,
    builder: (context) {
      return child;
    },
  );
}
