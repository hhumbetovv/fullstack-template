import 'package:flutter/material.dart';
import 'package:ui_foundation/public.dart';

final class ListBuilder<T> extends StatelessWidget {
  const ListBuilder({
    required this.items,
    required this.itemBuilder,
    super.key,
    this.physics = AppDefaults.scrollPhysics,
    this.clipBehavior = Clip.hardEdge,
    this.reverse = false,
    this.shrinkWrap = false,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.separator,
    this.controller,
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

  @override
  Widget build(BuildContext context) {
    if (separator != null) {
      return GlowingOverscrollIndicator(
        axisDirection: AxisDirection.down,
        color: Colors.red,
        child: ListView.separated(
          clipBehavior: clipBehavior,
          controller: controller,
          separatorBuilder: (context, index) {
            return separator!;
          },
          padding: padding,
          physics: physics,
          reverse: reverse,
          shrinkWrap: shrinkWrap,
          scrollDirection: scrollDirection,
          itemBuilder: (context, index) {
            return itemBuilder(items[index], index);
          },
          itemCount: items.length,
        ),
      );
    }
    return ListView.builder(
      clipBehavior: clipBehavior,
      padding: padding,
      controller: controller,
      physics: physics,
      reverse: reverse,
      shrinkWrap: shrinkWrap,
      scrollDirection: scrollDirection,
      itemBuilder: (context, index) {
        return itemBuilder(items[index], index);
      },
      itemCount: items.length,
    );
  }
}
