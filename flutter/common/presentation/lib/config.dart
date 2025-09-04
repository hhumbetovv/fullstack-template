import 'package:common_shared/constants.dart';
import 'package:flutter/material.dart';

class CommonPresentationConfig {
  factory CommonPresentationConfig() => _instance;
  CommonPresentationConfig._();
  static final _instance = CommonPresentationConfig._();
}

typedef SnackBarBuilder =
    SnackBar Function(
      String message,
      MessageType type,
    );
