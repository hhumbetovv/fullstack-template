// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PaletteAnnotation Generator
// **************************************************************************

part of 'navigator.dart';

@immutable
base class _NavigatorPalette implements NavigatorPalette {
  const _NavigatorPalette({
    required this.border,
    required this.background,
    required this.content,
    required this.selectedContent,
  });

  final Color border;

  final Color background;

  final Color content;

  final Color selectedContent;
}

extension NavigatorPaletteGetter on NavigatorPalette {
  _NavigatorPalette get _self => this as _NavigatorPalette;
  Color get border => _self.border;
  Color get background => _self.background;
  Color get content => _self.content;
  Color get selectedContent => _self.selectedContent;
}

extension NavigatorPaletteCopy on NavigatorPalette {
  NavigatorPalette copy({
    Color? border,
    Color? background,
    Color? content,
    Color? selectedContent,
  }) {
    return _NavigatorPalette(
      border: border ?? _self.border,
      background: background ?? _self.background,
      content: content ?? _self.content,
      selectedContent: selectedContent ?? _self.selectedContent,
    );
  }
}

extension NavigatorPaletteLerp on NavigatorPalette {
  NavigatorPalette lerp(NavigatorPalette other, double t) {
    return NavigatorPalette(
      border: Color.lerp(border, other.border, t) ?? other.border,
      background:
          Color.lerp(background, other.background, t) ?? other.background,
      content: Color.lerp(content, other.content, t) ?? other.content,
      selectedContent:
          Color.lerp(selectedContent, other.selectedContent, t) ??
          other.selectedContent,
    );
  }
}
