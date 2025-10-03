// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// RootPalette Generator
// **************************************************************************

part of 'palette.dart';

@immutable
base class _Palette implements Palette {
  const _Palette({
    required this.bottomSheet,
    required this.core,
    required this.color,
    required this.button,
    required this.textField,
    required this.navigator,
    required this.tab,
  });

  final BottomSheetPalette bottomSheet;

  final CorePalette core;

  final ColorPalette color;

  final ButtonPalette button;

  final TextFieldPalette textField;

  final NavigatorPalette navigator;

  final TabPalette tab;

  @override
  ThemeExtension<Palette> copyWith({
    BottomSheetPalette? bottomSheet,
    CorePalette? core,
    ColorPalette? color,
    ButtonPalette? button,
    TextFieldPalette? textField,
    NavigatorPalette? navigator,
    TabPalette? tab,
  }) {
    return Palette(
      bottomSheet: bottomSheet ?? this.bottomSheet,
      core: core ?? this.core,
      color: color ?? this.color,
      button: button ?? this.button,
      textField: textField ?? this.textField,
      navigator: navigator ?? this.navigator,
      tab: tab ?? this.tab,
    );
  }

  @override
  ThemeExtension<Palette> lerp(
    covariant ThemeExtension<Palette>? other,
    double t,
  ) {
    if (other is! Palette) return this;

    return Palette(
      bottomSheet: bottomSheet.lerp(other.bottomSheet, t),
      core: core.lerp(other.core, t),
      color: color.lerp(other.color, t),
      button: button.lerp(other.button, t),
      textField: textField.lerp(other.textField, t),
      navigator: navigator.lerp(other.navigator, t),
      tab: tab.lerp(other.tab, t),
    );
  }

  @override
  Object get type => Palette;
}

extension PaletteGetter on Palette {
  _Palette get _self => this as _Palette;
  BottomSheetPalette get bottomSheet => _self.bottomSheet;
  CorePalette get core => _self.core;
  ColorPalette get color => _self.color;
  ButtonPalette get button => _self.button;
  TextFieldPalette get textField => _self.textField;
  NavigatorPalette get navigator => _self.navigator;
  TabPalette get tab => _self.tab;
}

extension PaletteCopy on Palette {
  Palette copy({
    BottomSheetPalette? bottomSheet,
    CorePalette? core,
    ColorPalette? color,
    ButtonPalette? button,
    TextFieldPalette? textField,
    NavigatorPalette? navigator,
    TabPalette? tab,
  }) {
    return _Palette(
      bottomSheet: bottomSheet ?? _self.bottomSheet,
      core: core ?? _self.core,
      color: color ?? _self.color,
      button: button ?? _self.button,
      textField: textField ?? _self.textField,
      navigator: navigator ?? _self.navigator,
      tab: tab ?? _self.tab,
    );
  }
}

extension PaletteLerp on Palette {
  Palette lerp(Palette other, double t) {
    return Palette(
      bottomSheet: bottomSheet.lerp(other.bottomSheet, t),
      core: core.lerp(other.core, t),
      color: color.lerp(other.color, t),
      button: button.lerp(other.button, t),
      textField: textField.lerp(other.textField, t),
      navigator: navigator.lerp(other.navigator, t),
      tab: tab.lerp(other.tab, t),
    );
  }
}
