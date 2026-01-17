import 'package:flutter/material.dart';
import 'package:processor/public.dart';
import 'package:ui_components/src/palette/bottom_sheet.dart';
import 'package:ui_components/src/palette/button.dart';
import 'package:ui_components/src/palette/color.dart';
import 'package:ui_components/src/palette/core.dart';
import 'package:ui_components/src/palette/navigator.dart';
import 'package:ui_components/src/palette/tab.dart';
import 'package:ui_components/src/palette/text_field.dart';

part 'palette.g.dart';

@rootPalette
abstract class Palette extends ThemeExtension<Palette> {
  const factory Palette({
    required BottomSheetPalette bottomSheet,
    required CorePalette core,
    required ColorPalette color,
    required ButtonPalette button,
    required TextFieldPalette textField,
    required NavigatorPalette navigator,
    required TabPalette tab,
  }) = _Palette;
}
