import 'package:flutter/material.dart';

class AppHero extends Hero {
  const AppHero({
    required super.tag,
    required super.child,
    super.key,
    super.createRectTween,
    super.flightShuttleBuilder,
    super.placeholderBuilder,
  }) : super(
         transitionOnUserGestures: true,
       );
}
