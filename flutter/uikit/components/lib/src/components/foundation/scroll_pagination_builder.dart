import 'package:flutter/material.dart';
import 'package:ui_components/public.dart';

final class ScrollPaginationBuilder extends ScrollPaginationWidget {
  const ScrollPaginationBuilder({
    required this.builder,
    required super.fetch,
    required super.canFetch,
    super.key,
    super.controller,
  });

  final Widget Function(
    BuildContext context,
    ScrollController controller,
  )
  builder;

  @override
  ScrollPaginationState<ScrollPaginationBuilder> createState() => _InfinityScrollBuilderState();
}

class _InfinityScrollBuilderState extends ScrollPaginationState<ScrollPaginationBuilder> {
  @override
  Widget buildView(BuildContext context, ScrollController controller) {
    return widget.builder(context, controller);
  }
}
