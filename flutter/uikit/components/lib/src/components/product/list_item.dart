import 'package:flutter/widgets.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';

final class UiListItem extends StatelessWidget {
  const UiListItem({
    required this.title,
    required this.icon,
    required this.onClick,
    super.key,
    this.showTrailing = true,
    this.color,
  });

  final String title;
  final IconData icon;
  final VoidCallback onClick;
  final bool showTrailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            width: 0.5,
            color: context.palette.color.divider,
          ),
        ),
      ),
      child: Clickable(
        onTap: onClick,
        child: Padding(
          padding: const AppPadding.largeV(),
          child: Row(
            spacing: AppDimens.medium,
            children: [
              UiIcon(
                icon,
                color: color,
              ),
              UiText(
                title,
                color: color,
              ),
              const Spacer(),
              if (showTrailing) ...[
                const UiIcon(AppIcons.chevronRight),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
