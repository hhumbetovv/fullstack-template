// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PaletteAnnotation Generator
// **************************************************************************

part of 'text_field.dart';

@immutable
base class _TextFieldPalette implements TextFieldPalette {
  const _TextFieldPalette({required this.primary});

  final TextFieldTypePalette primary;
}

extension TextFieldPaletteGetter on TextFieldPalette {
  _TextFieldPalette get _self => this as _TextFieldPalette;
  TextFieldTypePalette get primary => _self.primary;
}

extension TextFieldPaletteCopy on TextFieldPalette {
  TextFieldPalette copy({TextFieldTypePalette? primary}) {
    return _TextFieldPalette(primary: primary ?? _self.primary);
  }
}

extension TextFieldPaletteLerp on TextFieldPalette {
  TextFieldPalette lerp(TextFieldPalette other, double t) {
    return TextFieldPalette(primary: primary.lerp(other.primary, t));
  }
}
