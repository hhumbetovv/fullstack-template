import 'package:flutter/material.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';

final class DarkTheme extends BaseTheme {
  const DarkTheme();

  static const background = AppColors.black400;
  static const content = AppColors.white;
  static const container = AppColors.black300;
  static const containerContent = AppColors.white;
  static const caption = AppColors.gray400;
  static const primary = AppColors.purple100;
  static const primaryDark = AppColors.purple200;
  static const divider = AppColors.black100;
  static const interactiveText = AppColors.white;
  static const error = AppColors.red100;

  @override
  Palette get palette {
    return Palette(
      core: const CorePalette(
        brightness: Brightness.light,
        contentBrightness: Brightness.dark,
      ),
      color: const ColorPalette(
        danger: error,
        background: background,
        content: content,
        container: container,
        containerContent: containerContent,
        caption: caption,
        primary: primary,
        primaryDark: primaryDark,
        divider: divider,
        interactiveText: interactiveText,
      ),
      button: const ButtonPalette(
        primary: ButtonTypePalette(
          background: primary,
          pressedBackground: primaryDark,
          content: content,
          border: Colors.transparent,
        ),
        danger: ButtonTypePalette(
          background: AppColors.red100,
          pressedBackground: AppColors.red200,
          content: content,
          border: Colors.transparent,
        ),
        secondary: ButtonTypePalette(
          background: container,
          pressedBackground: AppColors.black200,
          content: content,
          border: Colors.transparent,
        ),
        outlined: ButtonTypePalette(
          background: Colors.transparent,
          pressedBackground: AppColors.black300,
          content: primary,
          border: primary,
        ),
        secondaryOutlined: ButtonTypePalette(
          background: Colors.transparent,
          pressedBackground: AppColors.black300,
          content: content,
          border: AppColors.black200,
        ),
      ),
      textField: TextFieldPalette(
        primary: TextFieldTypePalette(
          idle: const TextFieldStatePalette(
            background: container,
            label: content,
            text: content,
            hint: caption,
            border: Colors.transparent,
            icon: caption,
          ),
          focused: TextFieldStatePalette(
            background: container,
            label: content,
            text: content,
            hint: caption,
            border: Color.alphaBlend(AppColors.white, AppColors.purple50),
            icon: content,
          ),
          error: const TextFieldStatePalette(
            background: container,
            text: content,
            label: content,
            hint: caption,
            border: error,
            icon: content,
          ),
        ),
      ),
      navigator: const NavigatorPalette(
        border: divider,
        background: background,
        content: caption,
        selectedContent: primary,
      ),
      bottomSheet: const BottomSheetPalette(
        background: AppColors.black400,
        indicator: AppColors.black200,
      ),
      tab: const TabPalette(
        idle: content,
        selected: primary,
      ),
    );
  }
}
