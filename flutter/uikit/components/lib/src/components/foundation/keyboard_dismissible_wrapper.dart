import 'dart:io';

import 'package:flutter/material.dart';

class KeyboardDismissibleWrapper extends StatelessWidget {
  const KeyboardDismissibleWrapper({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) return child;
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollStartNotification) {
          final currentFocus = FocusScope.of(context);
          if (currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        }
        return false;
      },
      child: child,
    );
  }
}
