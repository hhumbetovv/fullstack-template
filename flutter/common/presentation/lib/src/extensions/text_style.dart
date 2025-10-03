import 'package:flutter/material.dart';

extension TextStyleX on TextStyle {
  TextStyle scaled(TextScaler scaler) {
    return copyWith(
      fontSize: fontSize != null ? scaler.scale(fontSize!) : null,
    );
  }

  TextStyle colored(Color? color) {
    return copyWith(color: color);
  }
}
