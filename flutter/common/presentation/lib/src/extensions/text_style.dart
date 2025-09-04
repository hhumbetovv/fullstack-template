import 'package:flutter/material.dart';

extension TextStyleX on TextStyle {
  TextStyle withScaler(TextScaler scaler) {
    return copyWith(
      fontSize: fontSize != null ? scaler.scale(fontSize!) : null,
    );
  }

  TextStyle withColor(Color? color) {
    return copyWith(color: color);
  }
}
