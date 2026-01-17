import 'package:app/app/app.dart';
import 'package:app/app/provider.dart';
import 'package:app/config/config.dart';
import 'package:flutter/material.dart';

void main() async {
  await AppConfig.setup();

  runApp(
    AppProviderScope(
      child: const App(),
    ),
  );
}
