import 'package:flutter/material.dart';
import 'package:ui_components/public.dart';

final class UiDivider extends StatelessWidget {
  const UiDivider({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Divider(
      color: palette.color.divider,
      height: 1,
      thickness: 1,
    );
  }
}
