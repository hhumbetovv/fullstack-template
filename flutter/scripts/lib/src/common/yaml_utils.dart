import 'dart:convert';
import 'dart:io';

import 'logging.dart';

class YamlParser {
  static Map<String, dynamic> parse(String content) {
    final trimmedInput = content.trim();

    if (trimmedInput.startsWith('{') && trimmedInput.endsWith('}')) {
      final correctedJson = trimmedInput
          .replaceAllMapped(
            RegExp(r'(\w+):'),
            (match) => '"${match.group(1)}":',
          )
          .replaceAll(' ', '')
          .replaceAll('"', ' ')
          .replaceAll('{ ', '{')
          .replaceAll(' }', '}')
          .replaceAll(',', ', ');

      try {
        final decoded = json.decode(correctedJson.replaceAll("'", ' '));
        if (decoded is Map<String, dynamic>) return decoded;
        return {};
      } on Exception catch (_) {}
    }

    final lines = content.split('\n');
    final result = <String, dynamic>{};
    final indentationMap = <int, dynamic>{-2: result};
    var lastIndentation = -2;

    for (final line in lines) {
      final trimmedLine = line.trim();

      if (trimmedLine.isEmpty ||
          trimmedLine.startsWith('#') ||
          trimmedLine.startsWith('!')) {
        continue;
      }

      final currentIndentation = line.indexOf(trimmedLine);

      dynamic parent = indentationMap[lastIndentation];
      while (lastIndentation >= currentIndentation) {
        lastIndentation -= 2;
        parent = indentationMap[lastIndentation];
        if (parent != null) {
          break;
        }
      }

      if (trimmedLine.startsWith('-')) {
        if (parent is List) {
          final value = trimmedLine.substring(1).trim();
          parent.add(value);
        } else if (parent is Map &&
            parent.isNotEmpty &&
            parent.values.last is List) {
          final list = parent.values.last as List;
          final value = trimmedLine.substring(1).trim();
          list.add(value);
        }
      } else {
        final parts = trimmedLine.split(':');
        final key = parts[0].trim();
        final valuePart = parts.length > 1
            ? parts.sublist(1).join(':').trim()
            : '';

        if (valuePart.isEmpty) {
          final isListKey = key == 'workspace' || key == 'assets';
          final newObject = isListKey ? <dynamic>[] : <String, dynamic>{};

          if (parent is Map<String, dynamic>) {
            parent[key] = newObject;
          }

          indentationMap[currentIndentation] = newObject;
          lastIndentation = currentIndentation;
        } else {
          if (parent is Map<String, dynamic>) {
            parent[key] = valuePart;
          }
        }
      }
    }

    return result;
  }
}

Future<Map<String, dynamic>?> readPubspec(String filePath) async {
  try {
    final file = File(filePath);
    if (!file.existsSync()) return null;

    final content = await file.readAsString();
    return YamlParser.parse(content);
  } on Exception catch (e) {
    Logger.debug('Error reading $filePath: $e');
    return null;
  }
}

String? getPackageName(Map<String, dynamic> pubspec) =>
    pubspec['name']?.toString();

bool hasBuildRunner(Map<String, dynamic> pubspec) {
  final dependencies = pubspec['dependencies'] as Map<String, dynamic>?;
  final devDependencies = pubspec['dev_dependencies'] as Map<String, dynamic>?;

  return (dependencies?.containsKey('build_runner') ?? false) ||
      (devDependencies?.containsKey('build_runner') ?? false);
}

bool shouldIgnoreModule(String moduleName) {
  return moduleName.startsWith('gen_') ||
      moduleName.contains('generator') ||
      moduleName.contains('_gen');
}
