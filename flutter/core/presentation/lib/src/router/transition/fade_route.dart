import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:ui_foundation/public.dart';

final class FadeRoute extends CustomRoute<void> {
  FadeRoute({
    required super.page,
    super.children,
    super.initial,
    super.path,
    super.guards,
    super.keepHistory,
  }) : super(
         duration: const AppDuration.fade(),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return FadeTransition(
             opacity: animation,
             child: child,
           );
         },
       );
}
