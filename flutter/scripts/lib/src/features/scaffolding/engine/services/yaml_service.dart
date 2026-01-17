import 'dart:io';

import 'package:scripts/src/core/logging/logging.dart';
import 'package:yaml/yaml.dart';

dynamic _convertYamlValue(dynamic value) {
  if (value is YamlMap) {
    return Map<String, dynamic>.fromEntries(
      value.entries.map(
        (entry) => MapEntry(entry.key.toString(), _convertYamlValue(entry.value)),
      ),
    );
  }

  if (value is YamlList) {
    return value.map(_convertYamlValue).toList();
  }

  return value;
}

Future<Map<String, dynamic>?> readPubspec(String filePath) async {
  try {
    final file = File(filePath);
    if (!file.existsSync()) return null;

    final content = await file.readAsString();
    final parsed = loadYaml(content);
    final converted = _convertYamlValue(parsed);

    if (converted is Map<String, dynamic>) {
      return converted;
    }

    Logger.debug('Parsed pubspec did not produce a map: $filePath');
    return null;
  } on Object catch (e) {
    Logger.debug('Error reading $filePath: $e');
    return null;
  }
}

String? getPackageName(Map<String, dynamic> pubspec) => pubspec['name']?.toString();

bool hasBuildRunner(Map<String, dynamic> pubspec) {
  final dependencies = pubspec['dependencies'] as Map<String, dynamic>?;
  final devDependencies = pubspec['dev_dependencies'] as Map<String, dynamic>?;

  return (dependencies?.containsKey('build_runner') ?? false) ||
      (devDependencies?.containsKey('build_runner') ?? false);
}

bool shouldIgnoreModule(String moduleName) {
  return moduleName.startsWith('gen_') || moduleName.contains('generator') || moduleName.contains('_gen');
}
