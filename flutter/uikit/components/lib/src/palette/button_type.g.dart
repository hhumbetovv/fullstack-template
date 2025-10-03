// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PaletteAnnotation Generator
// **************************************************************************

part of 'button_type.dart';

@immutable
base class _ButtonTypePalette implements ButtonTypePalette {
  const _ButtonTypePalette({
    required this.background,
    required this.pressedBackground,
    required this.border,
    required this.content,
  });

  final Color background;

  final Color pressedBackground;

  final Color border;

  final Color content;
}

extension ButtonTypePaletteGetter on ButtonTypePalette {
  _ButtonTypePalette get _self => this as _ButtonTypePalette;
  Color get background => _self.background;
  Color get pressedBackground => _self.pressedBackground;
  Color get border => _self.border;
  Color get content => _self.content;
}

extension ButtonTypePaletteCopy on ButtonTypePalette {
  ButtonTypePalette copy({
    Color? background,
    Color? pressedBackground,
    Color? border,
    Color? content,
  }) {
    return _ButtonTypePalette(
      background: background ?? _self.background,
      pressedBackground: pressedBackground ?? _self.pressedBackground,
      border: border ?? _self.border,
      content: content ?? _self.content,
    );
  }
}

extension ButtonTypePaletteLerp on ButtonTypePalette {
  ButtonTypePalette lerp(ButtonTypePalette other, double t) {
    return ButtonTypePalette(
      background:
          Color.lerp(background, other.background, t) ?? other.background,
      pressedBackground:
          Color.lerp(pressedBackground, other.pressedBackground, t) ??
          other.pressedBackground,
      border: Color.lerp(border, other.border, t) ?? other.border,
      content: Color.lerp(content, other.content, t) ?? other.content,
    );
  }
}
