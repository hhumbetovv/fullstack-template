// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PaletteAnnotation Generator
// **************************************************************************

part of 'text_field_state.dart';

@immutable
base class _TextFieldStatePalette implements TextFieldStatePalette {
  const _TextFieldStatePalette({
    required this.background,
    required this.text,
    required this.hint,
    required this.label,
    required this.border,
    required this.icon,
  });

  final Color background;

  final Color text;

  final Color hint;

  final Color label;

  final Color border;

  final Color icon;
}

extension TextFieldStatePaletteGetter on TextFieldStatePalette {
  _TextFieldStatePalette get _self => this as _TextFieldStatePalette;
  Color get background => _self.background;
  Color get text => _self.text;
  Color get hint => _self.hint;
  Color get label => _self.label;
  Color get border => _self.border;
  Color get icon => _self.icon;
}

extension TextFieldStatePaletteCopy on TextFieldStatePalette {
  TextFieldStatePalette copy({
    Color? background,
    Color? text,
    Color? hint,
    Color? label,
    Color? border,
    Color? icon,
  }) {
    return _TextFieldStatePalette(
      background: background ?? _self.background,
      text: text ?? _self.text,
      hint: hint ?? _self.hint,
      label: label ?? _self.label,
      border: border ?? _self.border,
      icon: icon ?? _self.icon,
    );
  }
}

extension TextFieldStatePaletteLerp on TextFieldStatePalette {
  TextFieldStatePalette lerp(TextFieldStatePalette other, double t) {
    return TextFieldStatePalette(
      background:
          Color.lerp(background, other.background, t) ?? other.background,
      text: Color.lerp(text, other.text, t) ?? other.text,
      hint: Color.lerp(hint, other.hint, t) ?? other.hint,
      label: Color.lerp(label, other.label, t) ?? other.label,
      border: Color.lerp(border, other.border, t) ?? other.border,
      icon: Color.lerp(icon, other.icon, t) ?? other.icon,
    );
  }
}
