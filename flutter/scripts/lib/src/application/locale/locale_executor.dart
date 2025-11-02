import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/logging/console.dart';

class LocaleExecutor {
  const LocaleExecutor();

  Future<int> run({
    required String inputPath,
    required String outputPath,
  }) async {
    final inputDir = Directory(inputPath);
    if (!inputDir.existsSync()) {
      Console.error('Input directory not found: $inputPath');
      return 1;
    }

    final keys = _collectKeys(inputDir);
    if (keys.isEmpty) {
      Console.warning('No keys found in $inputPath.');
      return 0;
    }

    final buffer = StringBuffer()..writeln('sealed class LocaleKeys {');

    for (final key in keys.toList()..sort()) {
      final fieldName = _toCamelCase(key);
      if (fieldName.isEmpty) continue;
      buffer.writeln("  static const $fieldName = '$key';");
    }

    buffer.writeln('}');

    final outputFile = File(outputPath);
    outputFile.parent.createSync(recursive: true);
    outputFile.writeAsStringSync(buffer.toString());

    Console.success(
      'Locale keys successfully generated: ${p.normalize(outputFile.path)}',
    );
    return 0;
  }

  Set<String> _collectKeys(Directory inputDir) {
    final keys = <String>{};
    for (final entity in inputDir.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File || !entity.path.endsWith('.json')) {
        continue;
      }
      try {
        final content = entity.readAsStringSync();
        final jsonData = jsonDecode(content);
        keys.addAll(_extractKeys(jsonData));
      } on Object catch (error) {
        Console.warning('Failed to parse ${entity.path}: $error');
      }
    }
    return keys;
  }

  Iterable<String> _extractKeys(dynamic data) sync* {
    if (data is Map) {
      for (final entry in data.entries) {
        final key = entry.key;
        if (key is String) {
          yield key;
        }
        yield* _extractKeys(entry.value);
      }
    }
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
