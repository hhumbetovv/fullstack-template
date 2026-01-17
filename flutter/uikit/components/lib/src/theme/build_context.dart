import 'package:flutter/material.dart';
import 'package:ui_components/public.dart';

extension BuildContextThemeX on BuildContext {
  Palette get palette {
    return Theme.of(this).extension<Palette>() ?? BaseTheme.light.palette;
  }

  ThemeData get theme {
    return Theme.of(this);
  }
}
