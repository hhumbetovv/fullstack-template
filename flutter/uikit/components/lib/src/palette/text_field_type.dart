import 'package:processor/public.dart';
import 'package:ui_components/src/palette/text_field_state.dart';

part 'text_field_type.g.dart';

@palette
class TextFieldTypePalette {
  const factory TextFieldTypePalette({
    required TextFieldStatePalette idle,
    required TextFieldStatePalette error,
    required TextFieldStatePalette focused,
  }) = _TextFieldTypePalette;
}
