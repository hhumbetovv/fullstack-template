import 'package:flutter/material.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';

final class Loader extends StatefulWidget {
  const Loader({
    super.key,
    this.color,
    this.size = AppDefaults.loaderSize,
    this.duration = const AppDuration.loader(),
  });

  final double size;
  final Color? color;
  final Duration duration;

  @override
  State<Loader> createState() => _LoaderState();
}

class _LoaderState extends State<Loader> with TickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultColor = context.palette.color.content;
    return RotationTransition(
      turns: Tween<double>(begin: 1, end: 0).animate(controller),
      child: UiIcon(
        AppIcons.loader,
        color: widget.color ?? defaultColor,
        size: widget.size,
      ),
    );
  }
}
