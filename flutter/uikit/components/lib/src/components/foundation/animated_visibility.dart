import 'package:flutter/material.dart';
import 'package:ui_foundation/public.dart';

class AnimatedVisibility extends StatefulWidget {
  const AnimatedVisibility({
    required this.child,
    required this.isVisible,
    this.axisAlignment = 1,
    this.axis = Axis.vertical,
    this.fade = true,
    this.duration = const AppDuration.visibility(),
    this.curve = const AppCurves.fastInFastOut(),
    super.key,
  });

  final Widget child;
  final bool isVisible;
  final double axisAlignment;
  final Axis axis;
  final Duration duration;
  final bool fade;
  final Curve curve;

  @override
  State<AnimatedVisibility> createState() => _AnimatedVisibilityState();
}

class _AnimatedVisibilityState extends State<AnimatedVisibility> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.isVisible ? 0.0 : 1.0,
    );

    _animation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = SizeTransition(
      sizeFactor: _animation,
      axisAlignment: widget.axisAlignment,
      axis: widget.axis,
      child: widget.child,
    );

    if (widget.fade) {
      child = FadeTransition(
        opacity: _animation,
        child: child,
      );
    }

    return child;
  }
}
