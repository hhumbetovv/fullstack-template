import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:common_tooling/tooling.dart';

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

  CacheHit<Config>? read(AssetId inputId, int expectedHash) {
    final file = _fileFor(inputId);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final storedHash = decoded['hash'] as int?;
      if (storedHash == null || storedHash != expectedHash) {
        return null;
      }
      final rawConfig = decoded['config'];
      if (rawConfig is Map<String, dynamic>) {
        return CacheHit(hash: storedHash, config: fromJson(rawConfig));
      }
      return CacheHit(hash: storedHash);
    } on Object {
      return null;
    }
  }

  void write(AssetId inputId, int hash, Config? config) {
    final file = _fileFor(inputId);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    final payload = <String, dynamic>{
      'hash': hash,
      'config': toJson(config),
    };
    file.writeAsStringSync(jsonEncode(payload));
  }
}

class CacheHit<Config> {
  const CacheHit({
    required this.hash,
    this.config,
  });

  final int hash;
  final Config? config;
}
