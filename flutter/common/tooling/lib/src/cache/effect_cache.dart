import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../path/normalize.dart';
import 'cache_paths.dart';
import 'effect_entry.dart';

class EffectCache {
  EffectCache({String? root}) : _root = root;

  final String? _root;

  File get _file => File(effectsCachePath(root: _root));

  /// Loads all cached effect configurations from disk.
  List<CachedEffect> readAll() {
    if (!_file.existsSync()) return [];
    try {
      final content = _file.readAsStringSync();
      final jsonList = jsonDecode(content) as Iterable<dynamic>;
      return jsonList
          .whereType<Map<String, dynamic>>()
          .map(CachedEffect.fromJson)
          .toList();
    } on Exception {
      return [];
    }
  }

  /// Returns cached effects that belong to the given [viewModelClass].
  ///
  /// Throws a [StateError] when two effects with the same method signature
  /// are registered for different views of the same view-model.
  List<CachedEffect> readForViewModel(String viewModelClass) {
    final effects = readAll();
    final matching = <CachedEffect>[];
    final seenByMethod = <String, CachedEffect>{};

    for (final effect in effects) {
      if (effect.viewModel != viewModelClass) continue;

      final normalizedMethod = effect.method.name.replaceAll('_', '');
      final previous = seenByMethod[normalizedMethod];
      if (previous != null &&
          (previous.view != effect.view ||
              previous.viewModel != effect.viewModel)) {
        throw StateError(
          'There is an element with the same name but different configurations:\n\n'
          '${effect.method.name} in ${effect.view} and ${previous.view}\n',
        );
      }

      seenByMethod[normalizedMethod] = effect;
      matching.add(effect);
    }

    return matching;
  }

  /// Persists [effects] for a view so that subsequent builder steps can reuse
  /// the configuration.
  void upsertViewEffects({
    required String viewClassName,
    required List<CachedEffect> effects,
  }) {
    final all = readAll();
    final filtered =
        all.where((effect) => effect.view != viewClassName).toList()
          ..addAll(effects);

    _ensureFile();
    final payload = filtered.map((effect) => effect.toJson()).toList();
    _file.writeAsStringSync(jsonEncode(payload));
  }

  /// Removes any cached information for [viewClassName].
  void removeView(String viewClassName) {
    final all = readAll();
    final filtered = all
        .where((effect) => effect.view != viewClassName)
        .toList();
    if (filtered.length == all.length) return;

    _ensureFile();
    final payload = filtered.map((effect) => effect.toJson()).toList();
    _file.writeAsStringSync(jsonEncode(payload));
  }

  void _ensureFile() {
    final directory = Directory(p.dirname(_file.path));
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    if (!_file.existsSync()) {
      _file.createSync(recursive: true);
    }
  }
}

/// Builds a deterministic path to an effect cache file inside the build cache.
String effectCachePathForProject(String projectRoot) {
  final normalized = normalizeSystemPath(projectRoot);
  return effectsCachePath(root: normalized);
}
