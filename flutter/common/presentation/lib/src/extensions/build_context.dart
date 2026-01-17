import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  double get safeBottomValue {
    return MediaQueryData.fromView(View.of(this)).padding.bottom;
  }

  double get safeTopValue {
    return MediaQueryData.fromView(View.of(this)).padding.top;
  }

  EdgeInsets get safeBottomPadding {
    return EdgeInsets.only(bottom: safeBottomValue);
  }

  double get width {
    return MediaQuery.sizeOf(this).width;
  }

  double get height {
    return MediaQuery.sizeOf(this).height;
  }
}
