import 'package:processor/public.dart';
import 'package:ui_components/src/palette/text_field_type.dart';

part 'text_field.g.dart';

@palette
class TextFieldPalette {
  const factory TextFieldPalette({
    required TextFieldTypePalette primary,
  }) = _TextFieldPalette;
}
