import 'dart:convert';
import 'dart:io';

import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/locale/engine/pipelines/locale/locale_context.dart';

class CollectKeysStage implements Stage<LocaleContext> {
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
