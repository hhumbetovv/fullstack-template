// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PaletteAnnotation Generator
// **************************************************************************

part of 'button.dart';

@immutable
base class _ButtonPalette implements ButtonPalette {
  const _ButtonPalette({
    required this.primary,
    required this.secondary,
    required this.danger,
    required this.outlined,
    required this.secondaryOutlined,
  });

  final ButtonTypePalette primary;

  final ButtonTypePalette secondary;

  final ButtonTypePalette danger;

  final ButtonTypePalette outlined;

  final ButtonTypePalette secondaryOutlined;
}

extension ButtonPaletteGetter on ButtonPalette {
  _ButtonPalette get _self => this as _ButtonPalette;
  ButtonTypePalette get primary => _self.primary;
  ButtonTypePalette get secondary => _self.secondary;
  ButtonTypePalette get danger => _self.danger;
  ButtonTypePalette get outlined => _self.outlined;
  ButtonTypePalette get secondaryOutlined => _self.secondaryOutlined;
}

extension ButtonPaletteCopy on ButtonPalette {
  ButtonPalette copy({
    ButtonTypePalette? primary,
    ButtonTypePalette? secondary,
    ButtonTypePalette? danger,
    ButtonTypePalette? outlined,
    ButtonTypePalette? secondaryOutlined,
  }) {
    return _ButtonPalette(
      primary: primary ?? _self.primary,
      secondary: secondary ?? _self.secondary,
      danger: danger ?? _self.danger,
      outlined: outlined ?? _self.outlined,
      secondaryOutlined: secondaryOutlined ?? _self.secondaryOutlined,
    );
  }
}

extension ButtonPaletteLerp on ButtonPalette {
  ButtonPalette lerp(ButtonPalette other, double t) {
    return ButtonPalette(
      primary: primary.lerp(other.primary, t),
      secondary: secondary.lerp(other.secondary, t),
      danger: danger.lerp(other.danger, t),
      outlined: outlined.lerp(other.outlined, t),
      secondaryOutlined: secondaryOutlined.lerp(other.secondaryOutlined, t),
    );
  }
}
