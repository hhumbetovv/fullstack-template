import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/core/stage/runner.dart';

class LocaleContext {
  LocaleContext({
    required this.inputPath,
    required this.outputPath,
  });

  final String inputPath;
  final String outputPath;

  late Directory inputDir;
  Set<String> keys = const {};
  int exitCode = 0;
}

class LocalePipeline {
  const LocalePipeline();

  Future<LocaleContext> run(LocaleContext context) {
    return StageRunner<LocaleContext>(
      stages: <Stage<LocaleContext>>[
        _ValidateInputStage(),
        _CollectKeysStage(),
        _WriteOutputStage(),
      ],
    ).run(context);
  }
}

class _ValidateInputStage implements Stage<LocaleContext> {
  @override
  String get name => 'validate-input';

  @override
  Future<LocaleContext> run(LocaleContext context) async {
    final inputDir = Directory(context.inputPath);
    if (!inputDir.existsSync()) {
      throw CommandError('Input directory not found: ${context.inputPath}', exitCode: 1);
    }
    context.inputDir = inputDir;
    return context;
  }
}

class _CollectKeysStage implements Stage<LocaleContext> {
  @override
  String get name => 'collect-keys';

  @override
  Future<LocaleContext> run(LocaleContext context) async {
    final keys = <String>{};
    for (final entity in context.inputDir.listSync(
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
    context.keys = keys;
    return context;
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
}

class _WriteOutputStage implements Stage<LocaleContext> {
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
    final parts = sanitized.split(RegExp(r'\\s+'));
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
