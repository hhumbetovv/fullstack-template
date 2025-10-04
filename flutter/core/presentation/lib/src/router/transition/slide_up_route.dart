import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:ui_foundation/public.dart';

final class SlideUpRoute extends CustomRoute<void> {
  SlideUpRoute({
    required super.page,
    super.children,
    super.initial,
    super.path,
    super.guards,
    super.keepHistory,
  }) : super(
         duration: const AppDuration.fade(),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           const begin = Offset(0, 1);
           const end = Offset.zero;
           const curve = Curves.easeOutCubic;

           final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

           return SlideTransition(
             position: animation.drive(tween),
             child: child,
           );
         },
       );
}
