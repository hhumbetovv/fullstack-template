import 'package:flutter/cupertino.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';
import 'package:ui_previews/core/base_preview.dart';

final class ButtonShowCase extends StatelessWidget {
  const ButtonShowCase({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.palette.color.background,
      child: Padding(
        padding: const AppPadding.base(),
        child: Column(
          spacing: 20,
          children: [
            UIButton(
              text: 'Primary Button',
              palette: context.palette.button.primary,
            ),
            UIButton(
              text: 'Secondary Button',
              palette: context.palette.button.secondary,
            ),
            UIButton(
              text: 'Outlined Button',
              palette: context.palette.button.outlined,
            ),
            UIButton(
              text: 'Secondary Outlined Button',
              palette: context.palette.button.secondaryOutlined,
            ),
            UIButton(
              text: 'Danger Button',
              palette: context.palette.button.danger,
            ),
          ],
        ),
      ),
    );
  }
}

@BasePreview()
Widget button() => const ButtonShowCase();
