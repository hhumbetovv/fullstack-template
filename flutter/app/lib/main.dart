import 'package:app/app.dart';
import 'package:app/config/config.dart';
import 'package:flutter/material.dart';

void main() async {
  await AppConfig.setup();
  runApp(const App());
}
