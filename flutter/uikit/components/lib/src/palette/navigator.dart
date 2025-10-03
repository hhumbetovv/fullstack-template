import 'package:flutter/rendering.dart';
import 'package:processor/public.dart';

part 'navigator.g.dart';

@palette
class NavigatorPalette {
  const factory NavigatorPalette({
    required Color border,
    required Color background,
    required Color content,
    required Color selectedContent,
  }) = _NavigatorPalette;
}
