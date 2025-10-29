import 'dart:io';

import 'package:scripts/src/core/core.dart';

Future<void> runProcess(List<String> args) async {
  final process = await Process.start(
    args.first,
    args.sublist(1),
    mode: ProcessStartMode.inheritStdio,
  );
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw CommandError('Command failed: ${args.join(' ')}', exitCode: exitCode);
  }
}

String readAppVersion(Directory appDir) {
  final pubspec = File('${appDir.path}/pubspec.yaml');
  if (!pubspec.existsSync()) {
    throw const CommandError('app/pubspec.yaml not found', exitCode: 66);
  }
  final lines = pubspec.readAsLinesSync();
  for (final line in lines) {
    if (line.trim().startsWith('version:')) {
      return line.split(':')[1].trim();
    }
  }
  return '0.0.0';
}
