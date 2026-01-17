import 'package:flutter/services.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';

final class LightTheme extends BaseTheme {
  const LightTheme();

  static const primary = AppColors.purple100;
  static const primaryDark = AppColors.purple200;
  static const background = AppColors.white;
  static const content = AppColors.black400;
  static const caption = AppColors.gray400;
  static const container = AppColors.gray100;
  static const containerContent = AppColors.black300;
  static const indicator = AppColors.gray300;
  static const divider = AppColors.gray200;
  static const interactiveText = AppColors.purple200;
  static const danger = AppColors.red100;

  @override
  Palette get palette {
    return const Palette(
      bottomSheet: BottomSheetPalette(
        background: background,
        indicator: indicator,
      ),
      core: CorePalette(
        brightness: Brightness.light,
        contentBrightness: Brightness.dark,
      ),
      color: ColorPalette(
        background: background,
        content: content,
        container: container,
        containerContent: containerContent,
        caption: caption,
        primary: primary,
        primaryDark: primaryDark,
        divider: divider,
        interactiveText: interactiveText,
        danger: danger,
      ),
      button: ButtonPalette(
        primary: ButtonTypePalette(
          background: primary,
          border: AppColors.transparent,
          content: AppColors.white,
          pressedBackground: primaryDark,
        ),
        secondary: ButtonTypePalette(
          background: container,
          content: content,
          border: AppColors.transparent,
          pressedBackground: AppColors.gray200,
        ),
        danger: ButtonTypePalette(
          background: danger,
          content: AppColors.white,
          border: AppColors.transparent,
          pressedBackground: AppColors.red200,
        ),
        outlined: ButtonTypePalette(
          background: AppColors.transparent,
          content: primary,
          border: primary,
          pressedBackground: AppColors.gray200,
        ),
        secondaryOutlined: ButtonTypePalette(
          background: AppColors.transparent,
          content: content,
          border: primary,
          pressedBackground: AppColors.gray200,
        ),
      ),
      textField: TextFieldPalette(
        primary: TextFieldTypePalette(
          idle: TextFieldStatePalette(
            background: container,
            label: content,
            text: content,
            hint: caption,
            border: AppColors.transparent,
            icon: caption,
          ),
          error: TextFieldStatePalette(
            background: AppColors.red50,
            label: content,
            text: content,
            hint: caption,
            border: danger,
            icon: content,
          ),
          focused: TextFieldStatePalette(
            background: AppColors.purple50,
            label: content,
            text: content,
            hint: caption,
            border: primary,
            icon: content,
          ),
        ),
      ),
      navigator: NavigatorPalette(
        border: divider,
        background: background,
        content: caption,
        selectedContent: primary,
      ),
      tab: TabPalette(
        idle: content,
        selected: primary,
      ),
    );
  }
}
