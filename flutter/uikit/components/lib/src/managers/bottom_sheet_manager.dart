import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ui_components/public.dart';

class BottomSheetManager {
  static Completer<void>? _currentBottomSheetCompleter;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget content,
    Color? backgroundColor,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
  }) async {
    if (_currentBottomSheetCompleter != null && !_currentBottomSheetCompleter!.isCompleted) {
      Navigator.of(context).pop();
      await _currentBottomSheetCompleter!.future;
    }

    final completer = Completer<void>();
    _currentBottomSheetCompleter = completer;

    if (!context.mounted) return null;

    final result = await push<T>(
      context: context,
      content: content,
      backgroundColor: backgroundColor,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
    );

    if (!completer.isCompleted) {
      completer.complete();
    }
    _currentBottomSheetCompleter = null;

    return result;
  }

  static Future<T?> push<T>({
    required BuildContext context,
    required Widget content,
    Color? backgroundColor,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
  }) async {
    if (!context.mounted) return null;

    final result = await showModalBottomSheet<T>(
      scrollControlDisabledMaxHeightRatio: 1,
      context: context,
      builder: (_) => content,
      useRootNavigator: useRootNavigator,
      backgroundColor: backgroundColor ?? context.palette.color.background,
      isScrollControlled: isScrollControlled,
    );

    return result;
  }
}
