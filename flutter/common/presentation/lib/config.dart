import 'package:common_shared/constants.dart';
import 'package:flutter/material.dart';

class CommonPresentationConfig {
  factory CommonPresentationConfig() => _instance;
  CommonPresentationConfig._();
  static final _instance = CommonPresentationConfig._();

  late final SnackBarBuilder snackBarBuilder;

  static void setup({required SnackBarBuilder snackBarBuilder}) {
    _instance.snackBarBuilder = snackBarBuilder;
  }
}

typedef SnackBarBuilder =
    SnackBar Function(
      String message,
      MessageType type,
    );
