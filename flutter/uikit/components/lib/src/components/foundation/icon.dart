import 'package:flutter/widgets.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';

final class UiIcon extends StatelessWidget {
  const UiIcon(
    this.icon, {
    this.color,
    this.size = AppDefaults.iconSize,
    super.key,
  });

  final IconData icon;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color ?? context.palette.color.content,
    );
  }
}
