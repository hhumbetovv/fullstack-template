import 'package:flutter/material.dart';
import 'package:ui_foundation/public.dart';

final class AnimatedListItem extends StatefulWidget {
  const AnimatedListItem({
    required this.child,
    required this.width,
    super.key,
    this.delay = Duration.zero,
  });

  final Widget child;
  final double? width;
  final Duration delay;

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const AppDuration.visibility(),
  );

  late final Animation<double> animation = CurvedAnimation(
    parent: controller,
    curve: const AppCurves.fastInFastOut(),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, controller.forward);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: animation.drive(
          Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero),
        ),
        child: SizedBox(width: widget.width, child: widget.child),
      ),
    );
  }
}
