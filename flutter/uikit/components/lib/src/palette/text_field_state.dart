import 'package:flutter/rendering.dart';
import 'package:processor/public.dart';

part 'text_field_state.g.dart';

@palette
class TextFieldStatePalette {
  const factory TextFieldStatePalette({
    required Color background,
    required Color text,
    required Color hint,
    required Color label,
    required Color border,
    required Color icon,
  }) = _TextFieldStatePalette;
}
