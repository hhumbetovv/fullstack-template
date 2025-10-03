// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PaletteAnnotation Generator
// **************************************************************************

part of 'text_field_type.dart';

@immutable
base class _TextFieldTypePalette implements TextFieldTypePalette {
  const _TextFieldTypePalette({
    required this.idle,
    required this.error,
    required this.focused,
  });

  final TextFieldStatePalette idle;

  final TextFieldStatePalette error;

  final TextFieldStatePalette focused;
}

extension TextFieldTypePaletteGetter on TextFieldTypePalette {
  _TextFieldTypePalette get _self => this as _TextFieldTypePalette;
  TextFieldStatePalette get idle => _self.idle;
  TextFieldStatePalette get error => _self.error;
  TextFieldStatePalette get focused => _self.focused;
}

extension TextFieldTypePaletteCopy on TextFieldTypePalette {
  TextFieldTypePalette copy({
    TextFieldStatePalette? idle,
    TextFieldStatePalette? error,
    TextFieldStatePalette? focused,
  }) {
    return _TextFieldTypePalette(
      idle: idle ?? _self.idle,
      error: error ?? _self.error,
      focused: focused ?? _self.focused,
    );
  }
}

extension TextFieldTypePaletteLerp on TextFieldTypePalette {
  TextFieldTypePalette lerp(TextFieldTypePalette other, double t) {
    return TextFieldTypePalette(
      idle: idle.lerp(other.idle, t),
      error: error.lerp(other.error, t),
      focused: focused.lerp(other.focused, t),
    );
  }
}
