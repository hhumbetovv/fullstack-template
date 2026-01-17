import 'package:flutter/widgets.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';

final class UiIconButton extends StatelessWidget {
  const UiIconButton(
    this.icon, {
    this.alignment = Alignment.center,
    this.onTap,
    super.key,
    this.color,
    this.label,
    this.labelSpacing = AppDimens.micro,
    this.wrapperSize = AppDefaults.iconButtonSize,
    this.labelStyle = Styles.iconButton,
    this.padding = const AppPadding.smallV(),
    this.labelColor,
  });

  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  final String? label;
  final double labelSpacing;
  final Alignment alignment;
  final double wrapperSize;
  final TextStyle labelStyle;
  final Color? labelColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final icon = UiIcon(
      this.icon,
      color: color,
    );

    if (label != null) {
      return Clickable(
        onTap: onTap,
        child: UnconstrainedBox(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDefaults.iconButtonSize,
            ),
            child: Padding(
              padding: padding,
              child: Row(
                children: [
                  icon,
                  SizedBox(width: labelSpacing),
                  UiText(
                    label!,
                    style: labelStyle,
                    color: labelColor ?? color,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Clickable(
      onTap: onTap,
      child: SizedBox(
        height: wrapperSize,
        width: wrapperSize,
        child: Align(
          alignment: alignment,
          child: icon,
        ),
      ),
    );
  }
}
