import 'package:processor/public.dart';
import 'package:ui_components/src/palette/button_type.dart';

part 'button.g.dart';

@palette
class ButtonPalette {
  const factory ButtonPalette({
    required ButtonTypePalette primary,
    required ButtonTypePalette secondary,
    required ButtonTypePalette danger,
    required ButtonTypePalette outlined,
    required ButtonTypePalette secondaryOutlined,
  }) = _ButtonPalette;
}
