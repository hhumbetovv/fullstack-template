import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/locale/engine/pipelines/locale/locale_context.dart';

class WriteOutputStage implements Stage<LocaleContext> {
  @override
  String get name => 'write-output';

  @override
  Future<LocaleContext> run(LocaleContext context) async {
    if (context.keys.isEmpty) {
      Console.warning('No keys found in ${context.inputPath}.');
      context.exitCode = 0;
      return context;
    }

    final buffer = StringBuffer()..writeln('sealed class LocaleKeys {');

    for (final key in context.keys.toList()..sort()) {
      final fieldName = _toCamelCase(key);
      if (fieldName.isEmpty) continue;
      buffer.writeln("  static const $fieldName = '$key';");
    }

    buffer.writeln('}');

    final outputFile = File(context.outputPath);
    outputFile.parent.createSync(recursive: true);
    outputFile.writeAsStringSync(buffer.toString());

    Console.success(
      'Locale keys successfully generated: ${p.normalize(outputFile.path)}',
    );
    context.exitCode = 0;
    return context;
  }

  String _toCamelCase(String value) {
    final sanitized = value.replaceAll(RegExp('[^A-Za-z0-9]+'), ' ').trim();
    if (sanitized.isEmpty) {
      return '';
    }
    final parts = sanitized.split(RegExp(r'\s+'));
    final buffer = StringBuffer();
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isEmpty) continue;
      if (i == 0) {
        buffer.write(part.toLowerCase());
      } else {
        buffer
          ..write(part.substring(0, 1).toUpperCase())
          ..write(part.substring(1).toLowerCase());
      }
    }
    return buffer.toString();
  }
}
