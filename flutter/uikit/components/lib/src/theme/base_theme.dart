import 'package:flutter/material.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';

abstract class BaseTheme {
  const BaseTheme();

  abstract final Palette palette;

  static const light = LightTheme();

  ThemeData get data {
    return ThemeData(
      brightness: palette.core.brightness,
      colorSchemeSeed: palette.color.primary,
      scaffoldBackgroundColor: palette.color.background,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.startToEnd,
      ),
      primaryTextTheme: const TextTheme().apply(
        bodyColor: palette.color.content,
        displayColor: palette.color.content,
        decorationColor: palette.color.content,
      ),
      textTheme: const TextTheme().apply(
        bodyColor: palette.color.content,
        displayColor: palette.color.content,
        decorationColor: palette.color.content,
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: palette.color.primary.withValues(alpha: 0.5),
        cursorColor: palette.color.primary,
        selectionHandleColor: palette.color.primary,
      ),
      fontFamily: FontFamily.roboto,
      iconTheme: IconThemeData(
        size: AppDimens.macro,
        color: palette.color.content,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      extensions: [palette],
    );
  }
}
