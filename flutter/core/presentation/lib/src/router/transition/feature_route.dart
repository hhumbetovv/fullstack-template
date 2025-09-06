import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class FeatureRoute extends CustomRoute<void> {
  FeatureRoute({
    required super.page,
    super.children,
    super.initial,
    super.path,
    super.guards,
    super.keepHistory,
  }) : super(
         customRouteBuilder: materialRoute,
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
