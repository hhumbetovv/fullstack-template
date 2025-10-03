import 'package:flutter/material.dart';
import 'package:ui_foundation/public.dart';

enum ListAnimationType {
  slide,
  fade,
  zoom,
  fadeAndSize,
  slideAndFade,
  zoomAndFade,
}

final class AnimatedListBuilder<T> extends StatefulWidget {
  const AnimatedListBuilder({
    required this.items,
    required this.itemBuilder,
    this.physics = AppDefaults.scrollPhysics,
    this.clipBehavior = Clip.hardEdge,
    this.reverse = false,
    this.shrinkWrap = false,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.separator,
    this.controller,
    this.insertDuration = const Duration(milliseconds: 300),
    this.removeDuration = const Duration(milliseconds: 300),
    this.insertCurve = Curves.easeInOut,
    this.removeCurve = Curves.easeInOut,
    this.animationType = ListAnimationType.fadeAndSize,
    super.key,
  });

  final List<T> items;
  final Widget Function(T item, int index) itemBuilder;

  final Widget? separator;
  final Clip clipBehavior;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool reverse;
  final bool shrinkWrap;
  final Axis scrollDirection;
  final ScrollController? controller;

  final Duration insertDuration;
  final Duration removeDuration;
  final Curve insertCurve;
  final Curve removeCurve;
  final ListAnimationType animationType;

  @override
  State<AnimatedListBuilder<T>> createState() => _AnimatedListBuilderState<T>();
}

class _AnimatedListBuilderState<T> extends State<AnimatedListBuilder<T>> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<T> _currentItems;

  @override
  void initState() {
    super.initState();
    _currentItems = List.from(widget.items);
  }

  @override
  void didUpdateWidget(AnimatedListBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateList(oldWidget.items, widget.items);
  }

  void _updateList(List<T> oldItems, List<T> newItems) {
    for (var i = oldItems.length - 1; i >= 0; i--) {
      if (!newItems.contains(oldItems[i])) {
        final removedItem = _currentItems.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _buildRemovedItem(removedItem, i, animation),
          duration: widget.removeDuration,
        );
      }
    }

    for (var i = 0; i < newItems.length; i++) {
      if (i >= _currentItems.length || _currentItems[i] != newItems[i]) {
        if (!_currentItems.contains(newItems[i])) {
          _currentItems.insert(i, newItems[i]);
          _listKey.currentState?.insertItem(
            i,
            duration: widget.insertDuration,
          );
        }
      }
    }
  }

  Widget _buildAnimatedWidget(T item, int index, Animation<double> animation, {bool isRemoving = false}) {
    final child = widget.itemBuilder(item, index);

    switch (widget.animationType) {
      case ListAnimationType.slide:
        return _buildSlideAnimation(child, animation, isRemoving: isRemoving);

      case ListAnimationType.fade:
        return _buildFadeAnimation(child, animation);

      case ListAnimationType.zoom:
        return _buildZoomAnimation(child, animation);

      case ListAnimationType.fadeAndSize:
        return _buildFadeAndSizeAnimation(child, animation);

      case ListAnimationType.slideAndFade:
        return _buildSlideAndFadeAnimation(child, animation, isRemoving: isRemoving);

      case ListAnimationType.zoomAndFade:
        return _buildZoomAndFadeAnimation(child, animation);
    }
  }

  Widget _buildSlideAnimation(Widget child, Animation<double> animation, {bool isRemoving = false}) {
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: isRemoving ? Offset.zero : const Offset(1, 0),
          end: isRemoving ? const Offset(-1, 0) : Offset.zero,
        ).chain(
          CurveTween(
            curve: isRemoving ? widget.removeCurve : widget.insertCurve,
          ),
        ),
      ),
      child: child,
    );
  }

  Widget _buildFadeAnimation(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation.drive(
        CurveTween(curve: widget.insertCurve),
      ),
      child: child,
    );
  }

  Widget _buildZoomAnimation(Widget child, Animation<double> animation) {
    return ScaleTransition(
      scale: animation.drive(
        Tween<double>(begin: 0, end: 1).chain(
          CurveTween(curve: widget.insertCurve),
        ),
      ),
      child: child,
    );
  }

  Widget _buildFadeAndSizeAnimation(Widget child, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation.drive(
        CurveTween(curve: widget.insertCurve),
      ),
      child: FadeTransition(
        opacity: animation.drive(
          CurveTween(curve: widget.insertCurve),
        ),
        child: child,
      ),
    );
  }

  Widget _buildSlideAndFadeAnimation(Widget child, Animation<double> animation, {bool isRemoving = false}) {
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: isRemoving ? Offset.zero : const Offset(1, 0),
          end: isRemoving ? const Offset(-1, 0) : Offset.zero,
        ).chain(
          CurveTween(
            curve: isRemoving ? widget.removeCurve : widget.insertCurve,
          ),
        ),
      ),
      child: FadeTransition(
        opacity: animation.drive(
          CurveTween(curve: isRemoving ? widget.removeCurve : widget.insertCurve),
        ),
        child: child,
      ),
    );
  }

  Widget _buildZoomAndFadeAnimation(Widget child, Animation<double> animation) {
    return ScaleTransition(
      scale: animation.drive(
        Tween<double>(begin: 0, end: 1).chain(
          CurveTween(curve: widget.insertCurve),
        ),
      ),
      child: FadeTransition(
        opacity: animation.drive(
          CurveTween(curve: widget.insertCurve),
        ),
        child: child,
      ),
    );
  }

  Widget _buildRemovedItem(T item, int index, Animation<double> animation) {
    return _buildAnimatedWidget(item, index, animation, isRemoving: true);
  }

  Widget _buildItem(BuildContext context, int index, Animation<double> animation) {
    if (index >= _currentItems.length) return const SizedBox.shrink();

    final item = _currentItems[index];
    final animatedChild = _buildAnimatedWidget(item, index, animation);

    if (widget.separator != null && index < _currentItems.length - 1) {
      return Column(
        children: [
          animatedChild,
          widget.separator!,
        ],
      );
    }

    return animatedChild;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      clipBehavior: widget.clipBehavior,
      controller: widget.controller,
      padding: widget.padding,
      physics: widget.physics,
      reverse: widget.reverse,
      shrinkWrap: widget.shrinkWrap,
      scrollDirection: widget.scrollDirection,
      initialItemCount: _currentItems.length,
      itemBuilder: _buildItem,
    );
  }
}
