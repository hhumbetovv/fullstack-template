// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PaletteAnnotation Generator
// **************************************************************************

part of 'bottom_sheet.dart';

@immutable
base class _BottomSheetPalette implements BottomSheetPalette {
  const _BottomSheetPalette({
    required this.background,
    required this.indicator,
  });

  final Color background;

  final Color indicator;
}

extension BottomSheetPaletteGetter on BottomSheetPalette {
  _BottomSheetPalette get _self => this as _BottomSheetPalette;
  Color get background => _self.background;
  Color get indicator => _self.indicator;
}

extension BottomSheetPaletteCopy on BottomSheetPalette {
  BottomSheetPalette copy({Color? background, Color? indicator}) {
    return _BottomSheetPalette(
      background: background ?? _self.background,
      indicator: indicator ?? _self.indicator,
    );
  }
}

extension BottomSheetPaletteLerp on BottomSheetPalette {
  BottomSheetPalette lerp(BottomSheetPalette other, double t) {
    return BottomSheetPalette(
      background:
          Color.lerp(background, other.background, t) ?? other.background,
      indicator: Color.lerp(indicator, other.indicator, t) ?? other.indicator,
    );
  }
}
