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
      return jsonList.whereType<Map<String, dynamic>>().map(CachedEffect.fromJson).toList();
    } on Object {
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
    final seenBySignature = <String, CachedEffect>{};

    for (final effect in effects) {
      if (effect.viewModel != viewModelClass) {
        continue;
      }

      final signature = _methodSignature(effect.method);
      final previous = seenBySignature[signature];

      if (previous != null) {
        if (!_hasSameSignature(previous, effect)) {
          throw StateError(
            'There is an element with the same name but different configurations:\n\n'
            '${effect.method.name} in ${effect.view} and ${previous.view}\n',
          );
        }
        continue;
      }

      seenBySignature[signature] = effect;
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
    final filtered = all.where((effect) => effect.view != viewClassName).toList()..addAll(effects);

    _ensureFile();
    final payload = filtered.map((effect) => effect.toJson()).toList();
    _file.writeAsStringSync(jsonEncode(payload));
  }

  /// Removes any cached information for [viewClassName].
  void removeView(String viewClassName) {
    final all = readAll();
    final filtered = all.where((effect) => effect.view != viewClassName).toList();
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

String _methodSignature(CachedEffectMethod method) {
  final normalizedName = method.name.replaceAll('_', '');
  final buffer = StringBuffer(normalizedName);
  buffer.write('(');
  final params = method.params.where((param) => param.type != 'BuildContext');
  for (final param in params) {
    buffer
      ..write(param.type)
      ..write(':')
      ..write(param.name)
      ..write(';');
  }
  buffer.write(')');
  return buffer.toString();
}

bool _hasSameSignature(CachedEffect a, CachedEffect b) {
  if (a.viewModel != b.viewModel) {
    return false;
  }

  final aName = a.method.name.replaceAll('_', '');
  final bName = b.method.name.replaceAll('_', '');
  if (aName != bName) {
    return false;
  }

  final aParams = a.method.params.where((param) => param.type != 'BuildContext').toList();
  final bParams = b.method.params.where((param) => param.type != 'BuildContext').toList();

  if (aParams.length != bParams.length) {
    return false;
  }

  for (var index = 0; index < aParams.length; index += 1) {
    final aParam = aParams[index];
    final bParam = bParams[index];
    if (aParam.name != bParam.name || aParam.type != bParam.type) {
      return false;
    }
  }

  return true;
}

/// Builds a deterministic path to an effect cache file inside the build cache.
String effectCachePathForProject(String projectRoot) {
  final normalized = normalizeSystemPath(projectRoot);
  return effectsCachePath(root: normalized);
}
