import 'package:flutter/material.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';

final class ScrollPaginationListBuilder<T> extends StatelessWidget {
  const ScrollPaginationListBuilder({
    required this.items,
    required this.fetch,
    required this.itemBuilder,
    required this.canFetch,
    this.physics = AppDefaults.scrollPhysics,
    this.clipBehavior = Clip.hardEdge,
    this.reverse = false,
    this.shrinkWrap = false,
    this.scrollDirection = Axis.vertical,
    this.padding,
    super.key,
    this.separator,
    this.controller,
  });

  final List<T> items;
  final Widget Function(T item, int index) itemBuilder;
  final bool canFetch;
  final VoidCallback fetch;

  final Widget? separator;
  final Clip clipBehavior;
  final EdgeInsets? padding;
  final ScrollPhysics physics;
  final bool reverse;
  final bool shrinkWrap;
  final Axis scrollDirection;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return ScrollPaginationBuilder(
      fetch: fetch,
      canFetch: canFetch,
      controller: controller,
      builder: (context, builderController) {
        return Builder(
          builder: (context) {
            return ListBuilder(
              key: key,
              items: items,
              clipBehavior: clipBehavior,
              separator: separator,
              controller: builderController,
              padding: padding,
              physics: physics,
              reverse: reverse,
              shrinkWrap: shrinkWrap,
              scrollDirection: scrollDirection,
              itemBuilder: itemBuilder,
            );
          },
        );
      },
    );
  }
}
