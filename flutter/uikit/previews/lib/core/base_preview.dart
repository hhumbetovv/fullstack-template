import 'package:flutter/widget_previews.dart';
import 'package:ui_components/public.dart';

final class BasePreview extends Preview {
  const BasePreview({
    super.name,
    super.group,
    super.size,
    super.textScaleFactor,
    super.wrapper,
    super.brightness,
    super.localizations,
  });

  PreviewThemeData _themeBuilder() {
    return PreviewThemeData(
      materialLight: const LightTheme().data,
      materialDark: const DarkTheme().data,
    );
  }

  @override
  Preview transform() {
    final originalPreview = super.transform();
    final builder = originalPreview.toBuilder()
      ..name = '${originalPreview.name}'
      ..theme = _themeBuilder;
    return builder.build();
  }
}
