import 'package:flutter/material.dart';
import 'package:ui_components/public.dart';

extension ThemeDataX on ThemeData {
  ThemeData applyColor(
    BuildContext context,
    ColorPalette Function(ColorPalette) applier,
  ) {
    final palette = context.palette;
    return context.theme.copyWith(
      extensions: [
        palette.copy(
          color: applier(palette.color),
        ),
      ],
    );
  }
}
