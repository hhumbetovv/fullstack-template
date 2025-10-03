// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PaletteAnnotation Generator
// **************************************************************************

part of 'tab.dart';

@immutable
base class _TabPalette implements TabPalette {
  const _TabPalette({required this.idle, required this.selected});

  final Color idle;

  final Color selected;
}

extension TabPaletteGetter on TabPalette {
  _TabPalette get _self => this as _TabPalette;
  Color get idle => _self.idle;
  Color get selected => _self.selected;
}

extension TabPaletteCopy on TabPalette {
  TabPalette copy({Color? idle, Color? selected}) {
    return _TabPalette(
      idle: idle ?? _self.idle,
      selected: selected ?? _self.selected,
    );
  }
}

extension TabPaletteLerp on TabPalette {
  TabPalette lerp(TabPalette other, double t) {
    return TabPalette(
      idle: Color.lerp(idle, other.idle, t) ?? other.idle,
      selected: Color.lerp(selected, other.selected, t) ?? other.selected,
    );
  }
}
