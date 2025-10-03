import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';

final class UiIcon extends StatelessWidget {
  const UiIcon(
    this.icon, {
    this.color,
    this.useDefaultColor = false,
    this.size = AppDefaults.iconSize,
    super.key,
  }) : height = null,
       width = null;

  const UiIcon.dimensions(
    this.icon, {
    required this.height,
    required this.width,
    this.useDefaultColor = false,
    this.color,
    super.key,
  }) : size = null;

  const UiIcon.full(
    this.icon, {
    this.useDefaultColor = false,
    this.color,
    super.key,
  }) : size = double.maxFinite,
       height = null,
       width = null;

  final AppIcons icon;
  final Color? color;
  final bool useDefaultColor;
  final double? size;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      icon.path,
      height: size ?? height,
      width: size ?? width,
      package: 'ui_foundation',
      colorFilter: !useDefaultColor
          ? ColorFilter.mode(
              color ?? context.palette.color.content,
              BlendMode.srcIn,
            )
          : null,
    );
  }
}
