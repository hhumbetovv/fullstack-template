import 'package:flutter/widgets.dart';

sealed class AppDefaults {
  static const appBarHeight = 42.0;
  static const buttonHeight = 42.0;
  static const smallButtonHeight = 36.0;
  static const loaderSize = 32.0;
  static const buttonLoaderSize = 26.0;
  static const iconSize = 20.0;
  static const iconButtonSize = 36.0;
  static const iconButtonLargeSize = 42.0;
  static const textFieldHeight = 42.0;
  static const clickableOpacity = 0.5;
  static const scrollPhysics = AlwaysScrollableScrollPhysics(
    parent: ClampingScrollPhysics(),
  );
  static const avatarRadius = 21.0;
  static const avatarLargeRadius = 32.0;
}
