import 'package:flutter/rendering.dart';
import 'package:processor/public.dart';

part 'tab.g.dart';

@palette
class TabPalette {
  const factory TabPalette({
    required Color idle,
    required Color selected,
  }) = _TabPalette;
}
