import 'package:common_presentation/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class UiDebugger {
  static void toggleDebugPaint() {
    if (!debugPaintLayerBordersEnabled &&
        !debugRepaintRainbowEnabled &&
        !debugPaintSizeEnabled &&
        !debugPaintBaselinesEnabled) {
      debugPaintLayerBordersEnabled = true;
    } else if (debugPaintLayerBordersEnabled) {
      debugPaintLayerBordersEnabled = false;
      debugRepaintRainbowEnabled = true;
    } else if (debugRepaintRainbowEnabled) {
      debugRepaintRainbowEnabled = false;
      debugPaintSizeEnabled = true;
    } else if (debugPaintSizeEnabled) {
      debugPaintSizeEnabled = false;
      debugPaintBaselinesEnabled = true;
    } else if (debugPaintBaselinesEnabled) {
      debugPaintBaselinesEnabled = false;
    }

    WidgetsBinding.instance.scheduleFrameCallback((_) {
      void rebuild(Element el) {
        el
          ..markNeedsBuild()
          ..visitChildren(rebuild);
      }

      final context = applicationKey.currentContext;
      if (context != null) {
        (context as Element).visitChildren(rebuild);
      }
    });
  }
}
