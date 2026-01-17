import 'package:flutter/foundation.dart';
import 'package:processor/public.dart';

part 'core.g.dart';

@palette
class CorePalette {
  const factory CorePalette({
    required Brightness brightness,
    required Brightness contentBrightness,
  }) = _CorePalette;
}
