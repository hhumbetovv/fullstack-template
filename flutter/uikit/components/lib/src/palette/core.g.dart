// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PaletteAnnotation Generator
// **************************************************************************

part of 'core.dart';

@immutable
base class _CorePalette implements CorePalette {
  const _CorePalette({
    required this.brightness,
    required this.contentBrightness,
  });

  final Brightness brightness;

  final Brightness contentBrightness;
}

extension CorePaletteGetter on CorePalette {
  _CorePalette get _self => this as _CorePalette;
  Brightness get brightness => _self.brightness;
  Brightness get contentBrightness => _self.contentBrightness;
}

extension CorePaletteCopy on CorePalette {
  CorePalette copy({Brightness? brightness, Brightness? contentBrightness}) {
    return _CorePalette(
      brightness: brightness ?? _self.brightness,
      contentBrightness: contentBrightness ?? _self.contentBrightness,
    );
  }
}

extension CorePaletteLerp on CorePalette {
  CorePalette lerp(CorePalette other, double t) {
    return CorePalette(
      brightness: other.brightness,
      contentBrightness: other.contentBrightness,
    );
  }
}
