// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PaletteAnnotation Generator
// **************************************************************************

part of 'color.dart';

@immutable
base class _ColorPalette implements ColorPalette {
  const _ColorPalette({
    required this.background,
    required this.content,
    required this.container,
    required this.containerContent,
    required this.caption,
    required this.primary,
    required this.primaryDark,
    required this.divider,
    required this.interactiveText,
    required this.danger,
  });

  final Color background;

  final Color content;

  final Color container;

  final Color containerContent;

  final Color caption;

  final Color primary;

  final Color primaryDark;

  final Color divider;

  final Color interactiveText;

  final Color danger;
}

extension ColorPaletteGetter on ColorPalette {
  _ColorPalette get _self => this as _ColorPalette;
  Color get background => _self.background;
  Color get content => _self.content;
  Color get container => _self.container;
  Color get containerContent => _self.containerContent;
  Color get caption => _self.caption;
  Color get primary => _self.primary;
  Color get primaryDark => _self.primaryDark;
  Color get divider => _self.divider;
  Color get interactiveText => _self.interactiveText;
  Color get danger => _self.danger;
}

extension ColorPaletteCopy on ColorPalette {
  ColorPalette copy({
    Color? background,
    Color? content,
    Color? container,
    Color? containerContent,
    Color? caption,
    Color? primary,
    Color? primaryDark,
    Color? divider,
    Color? interactiveText,
    Color? danger,
  }) {
    return _ColorPalette(
      background: background ?? _self.background,
      content: content ?? _self.content,
      container: container ?? _self.container,
      containerContent: containerContent ?? _self.containerContent,
      caption: caption ?? _self.caption,
      primary: primary ?? _self.primary,
      primaryDark: primaryDark ?? _self.primaryDark,
      divider: divider ?? _self.divider,
      interactiveText: interactiveText ?? _self.interactiveText,
      danger: danger ?? _self.danger,
    );
  }
}

extension ColorPaletteLerp on ColorPalette {
  ColorPalette lerp(ColorPalette other, double t) {
    return ColorPalette(
      background:
          Color.lerp(background, other.background, t) ?? other.background,
      content: Color.lerp(content, other.content, t) ?? other.content,
      container: Color.lerp(container, other.container, t) ?? other.container,
      containerContent:
          Color.lerp(containerContent, other.containerContent, t) ??
          other.containerContent,
      caption: Color.lerp(caption, other.caption, t) ?? other.caption,
      primary: Color.lerp(primary, other.primary, t) ?? other.primary,
      primaryDark:
          Color.lerp(primaryDark, other.primaryDark, t) ?? other.primaryDark,
      divider: Color.lerp(divider, other.divider, t) ?? other.divider,
      interactiveText:
          Color.lerp(interactiveText, other.interactiveText, t) ??
          other.interactiveText,
      danger: Color.lerp(danger, other.danger, t) ?? other.danger,
    );
  }
}
