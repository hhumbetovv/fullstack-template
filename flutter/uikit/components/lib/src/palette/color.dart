import 'package:flutter/rendering.dart';
import 'package:processor/public.dart';

part 'color.g.dart';

@palette
class ColorPalette {
  const factory ColorPalette({
    required Color background,
    required Color content,
    required Color container,
    required Color containerContent,
    required Color caption,
    required Color primary,
    required Color primaryDark,
    required Color divider,
    required Color interactiveText,
    required Color danger,
  }) = _ColorPalette;
}
