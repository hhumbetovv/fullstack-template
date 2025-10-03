import 'package:flutter/rendering.dart';
import 'package:processor/public.dart';

part 'button_type.g.dart';

@palette
class ButtonTypePalette {
  const factory ButtonTypePalette({
    required Color background,
    required Color pressedBackground,
    required Color border,
    required Color content,
  }) = _ButtonTypePalette;
}
