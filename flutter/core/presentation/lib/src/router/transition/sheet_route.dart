import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

final class SheetRoute extends CustomRoute<void> {
  SheetRoute({
    required super.page,
    super.children,
    super.initial,
    super.path,
    super.guards,
    super.keepHistory,
  }) : super(
         customRouteBuilder: modalSheetBuilder,
         fullscreenDialog: false,
         barrierDismissible: true,
       );
}

Route<T> modalSheetBuilder<T>(BuildContext context, Widget child, AutoRoutePage<T> page) {
  return ModalBottomSheetRoute(
    settings: page,
    builder: (context) => child,
    isScrollControlled: true,
  );
}
