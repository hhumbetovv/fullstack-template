import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

final class SheetRoute extends NamedRouteDef {
  SheetRoute({
    required super.name,
    required super.builder,
    super.children,
    super.initial,
    super.path,
    super.guards,
    super.keepHistory,
  }) : super(
         fullscreenDialog: false,
         type: RouteType.custom(
           customRouteBuilder: modalSheetBuilder,
           barrierDismissible: true,
         ),
       );
}

Route<T> modalSheetBuilder<T>(BuildContext context, Widget child, AutoRoutePage<T> page) {
  return ModalBottomSheetRoute(
    settings: page,
    builder: (context) => child,
    isScrollControlled: true,
  );
}
