import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ui_foundation/public.dart';

final class Clickable extends StatefulWidget {
  const Clickable({
    required this.child,
    this.onTap,
    this.pressedOpacity = AppDefaults.clickableOpacity,
    this.disabledOpacity = AppDefaults.clickableOpacity,
    bool? isDisabled,
    this.duration = const AppDuration.opacity(),
    this.onAnimationChanged,
    super.key,
    this.behavior = HitTestBehavior.opaque,
    this.onDoubleTap,
    this.onLongPress,
    this.semanticId,
  }) : isDisabled = isDisabled ?? (onTap == null && onDoubleTap == null && onLongPress == null);

  final Widget child;

  final HitTestBehavior? behavior;

  final bool isDisabled;
  final double pressedOpacity;
  final double disabledOpacity;
  final Duration duration;

  final ValueChanged<double>? onAnimationChanged;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final String? semanticId;

  @override
  State<Clickable> createState() => _ClickableState();
}

class _ClickableState extends State<Clickable> with SingleTickerProviderStateMixin {
  static const Duration kFadeOutDuration = Duration(milliseconds: 120);
  static const Duration kFadeInDuration = Duration(milliseconds: 180);
  final Tween<double> _opacityTween = Tween<double>(begin: 1);

  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      value: 0,
      vsync: this,
    );
    _opacityAnimation = _animationController
        .drive(
          CurveTween(curve: Curves.decelerate),
        )
        .drive(
          _opacityTween,
        );

    _animationController.addListener(animationListener);

    _setTween();
  }

  void animationListener() {
    widget.onAnimationChanged?.call(_animationController.value);
  }

  @override
  void didUpdateWidget(covariant Clickable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setTween();
  }

  void _setTween() {
    _opacityTween.end = widget.pressedOpacity;
  }

  @override
  void dispose() {
    _animationController
      ..removeListener(animationListener)
      ..dispose();
    super.dispose();
  }

  bool _buttonHeldDown = false;

  void _handleTapDown(TapDownDetails event) {
    if (!_buttonHeldDown) {
      _buttonHeldDown = true;
      _animate();
    }
  }

  void _handleTapUp(TapUpDetails event) {
    if (_buttonHeldDown) {
      _buttonHeldDown = false;
      _animate();
    }
  }

  void _handleTapCancel() {
    if (_buttonHeldDown) {
      _buttonHeldDown = false;
      _animate();
    }
  }

  void _animate() {
    if (_animationController.isAnimating) {
      return;
    }
    final wasHeldDown = _buttonHeldDown;
    (_buttonHeldDown
            ? _animationController.animateTo(1, duration: kFadeOutDuration, curve: Curves.easeInOutCubicEmphasized)
            : _animationController.animateTo(0, duration: kFadeInDuration, curve: Curves.easeOutCubic))
        .then<void>((void value) {
          if (mounted && wasHeldDown != _buttonHeldDown) {
            _animate();
          }
        });
  }

  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isDisabled) {
      return Opacity(
        opacity: widget.disabledOpacity,
        child: widget.child,
      );
    }
    return Semantics(
      identifier: widget.semanticId,
      label: widget.semanticId,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: GestureDetector(
          behavior: widget.behavior,
          onLongPress: widget.onLongPress,
          onTapDown: widget.isDisabled ? null : _handleTapDown,
          onTapUp: widget.isDisabled ? null : _handleTapUp,
          onTapCancel: widget.isDisabled ? null : _handleTapCancel,
          onTap: widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          child: widget.child,
        ),
      ),
    );
  }
}
