import 'package:flutter/material.dart';
import 'package:ui_components/public.dart';

final class UiRefreshIndicator extends StatelessWidget {
  const UiRefreshIndicator({
    required this.child,
    required this.onRefresh,
    super.key,
  });

  final Widget child;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: palette.color.primary,
      backgroundColor: palette.color.background,
      child: child,
    );
  }
}
