import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:ui_foundation/public.dart';

final class FadeRoute extends NamedRouteDef {
  FadeRoute({
    required super.name,
    required super.builder,
    super.children,
    super.initial,
    super.path,
    super.guards,
    super.keepHistory,
  }) : super(
         type: RouteType.custom(
           duration: const AppDuration.fade(),
           transitionsBuilder: (context, animation, secondaryAnimation, child) {
             return FadeTransition(
               opacity: animation,
               child: child,
             );
           },
         ),
       );
}
