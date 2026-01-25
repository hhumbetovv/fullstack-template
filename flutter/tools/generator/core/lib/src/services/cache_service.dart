import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:tools_common/tooling.dart';

/// Persists generator configurations under the shared build cache path so
/// repeated builds can short-circuit when nothing relevant changed.
class BuildCacheService<Config> {
  BuildCacheService({
    required this.builderName,
    required this.toJson,
    required this.fromJson,
  });

  final String builderName;
  final Map<String, dynamic>? Function(Config? config) toJson;
  final Config Function(Map<String, dynamic> json) fromJson;

  File _fileFor(AssetId inputId) {
    return File(
      buildCacheFilePath(
        name: builderName,
        id: inputId.path.hashCode,
      ),
    );
  }

  Config? read(AssetId inputId, int expectedHash) {
    final file = _fileFor(inputId);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is Map<String, dynamic>) {
        final cached = fromJson(decoded);
        if (cached.hashCode == expectedHash) {
          return cached;
        }
      }
    } on Object {
      return null;
    }
    return null;
  }

  void write(AssetId inputId, Config? config) {
    final file = _fileFor(inputId);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    final payload = jsonEncode(toJson(config));
    file.writeAsStringSync(payload);
  }
}
