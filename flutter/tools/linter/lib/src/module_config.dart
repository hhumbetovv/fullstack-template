import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

class ModuleLintRules {
  ModuleLintRules({
    Map<String, Set<String>>? layerPackages,
  }) : layerPackages = layerPackages ?? const {};

  final Map<String, Set<String>> layerPackages;

  bool get hasLayerRules => layerPackages.isNotEmpty;

  Set<String>? packagesForLayer(String layer) => layerPackages[layer];
}

ModuleLintRules? loadModuleLintRules({
  required Directory workspaceRoot,
  required Directory moduleDirectory,
}) {
  final configFile = File(path.join(moduleDirectory.path, 'module.yaml'));
  if (!configFile.existsSync()) {
    return null;
  }

  final data = _readYaml(configFile, workspaceRoot);
  final lintSpec = data['lint'];
  if (lintSpec == null) {
    return null;
  }

  final resolved = _resolveConfigValue(
    spec: lintSpec,
    moduleDirectory: moduleDirectory,
    workspaceRoot: workspaceRoot,
  );
  if (resolved is! Map) {
    return null;
  }

  final lintMap = _asStringKeyedMap(resolved);
  final featureLayers = lintMap['feature_layers'];
  if (featureLayers is! Map) {
    return ModuleLintRules();
  }

  final layerMap = _asStringKeyedMap(featureLayers);
  final layerPackages = _parseLayerPackages(layerMap);
  if (layerPackages.isEmpty) {
    return ModuleLintRules();
  }
  return ModuleLintRules(layerPackages: layerPackages);
}

Map<String, dynamic> _readYaml(File file, Directory workspaceRoot) {
  final content = file.readAsStringSync();
  final node = loadYamlNode(content, sourceUrl: file.uri);
  final includeStack = <String>{file.path};
  final data = _convertYamlNode(
    node,
    file,
    includeStack,
    workspaceRoot,
  );
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is Map) {
    return _asStringKeyedMap(data);
  }
  throw FormatException('module.yaml must be a map at ${file.path}');
}

dynamic _convertYamlNode(
  YamlNode node,
  File currentFile,
  Set<String> includeStack,
  Directory workspaceRoot,
) {
  if (node is YamlScalar) {
    return node.value;
  }
  if (node is YamlMap) {
    final result = <String, dynamic>{};
    node.nodes.forEach((dynamic keyNode, YamlNode valueNode) {
      final key = _convertYamlNode(
        keyNode as YamlNode,
        currentFile,
        includeStack,
        workspaceRoot,
      )?.toString();
      if (key == null || key.isEmpty) {
        return;
      }
      result[key] = _convertYamlNode(
        valueNode,
        currentFile,
        includeStack,
        workspaceRoot,
      );
    });
    return _maybeConvertIncludeDirective(
      result,
      currentFile,
      includeStack,
      workspaceRoot,
    );
  }
  if (node is YamlList) {
    return node.nodes
        .map((child) => _convertYamlNode(child, currentFile, includeStack, workspaceRoot))
        .toList();
  }
  return node.value;
}

dynamic _maybeConvertIncludeDirective(
  Map<String, dynamic> map,
  File currentFile,
  Set<String> includeStack,
  Directory workspaceRoot,
) {
  if (!_isIncludeDirective(map)) {
    return map;
  }
  final includeValue = map['include']?.toString().trim();
  if (includeValue == null || includeValue.isEmpty) {
    throw FormatException('Empty include path in ${currentFile.path}');
  }
  final raw = _parseRawFlag(map['raw']);
  final includeFile = _resolveIncludeFile(
    includeValue,
    currentFile.parent,
    workspaceRoot,
  );
  if (!includeStack.add(includeFile.path)) {
    throw FormatException('Circular include detected for $includeValue in ${currentFile.path}');
  }
  try {
    final content = includeFile.readAsStringSync();
    if (raw) {
      return content;
    }
    final node = loadYamlNode(content, sourceUrl: includeFile.uri);
    return _convertYamlNode(node, includeFile, includeStack, workspaceRoot);
  } finally {
    includeStack.remove(includeFile.path);
  }
}

bool _isIncludeDirective(Map<String, dynamic> map) {
  if (!map.containsKey('include')) {
    return false;
  }
  // If include is a List, this should be handled by _expandInlineIncludes, not here
  if (map['include'] is List) {
    return false;
  }
  const allowed = {'include', 'raw'};
  return map.keys.every(allowed.contains);
}

bool _parseRawFlag(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value == null) {
    return false;
  }
  final normalized = value.toString().toLowerCase().trim();
  return normalized == 'true' || normalized == 'yes';
}

dynamic _resolveConfigValue({
  required dynamic spec,
  required Directory moduleDirectory,
  required Directory workspaceRoot,
}) {
  if (spec == null) {
    return null;
  }
  final normalized = _normalizeValue(spec);
  if (normalized == null) {
    return null;
  }
  return _expandInlineIncludes(
    normalized,
    moduleDirectory,
    workspaceRoot,
    allowInlineIncludeKey: true,
  );
}

dynamic _normalizeValue(dynamic value) {
  if (value is Map) {
    final result = <String, dynamic>{};
    value.forEach((dynamic key, dynamic entryValue) {
      final normalizedKey = key?.toString();
      if (normalizedKey == null || normalizedKey.isEmpty) {
        return;
      }
      result[normalizedKey] = _normalizeValue(entryValue);
    });
    return result;
  }
  if (value is List) {
    return value.map(_normalizeValue).toList();
  }
  return value;
}

dynamic _expandInlineIncludes(
  dynamic value,
  Directory moduleDirectory,
  Directory workspaceRoot, {
  required bool allowInlineIncludeKey,
}) {
  if (value is Map) {
    final map = _asStringKeyedMap(value);
    if (allowInlineIncludeKey && map.containsKey('include')) {
      final includeValue = map['include'];
      final remaining = Map<String, dynamic>.from(map)..remove('include');
      final includeValues = _loadInlineIncludeValues(
        includeValue,
        moduleDirectory,
        workspaceRoot,
      );
      dynamic merged;
      for (final entry in includeValues) {
        final expanded = _expandInlineIncludes(
          entry,
          moduleDirectory,
          workspaceRoot,
          allowInlineIncludeKey: true,
        );
        merged = _mergeConfigValues(merged, expanded);
      }
      if (remaining.isEmpty) {
        return merged;
      }
      final expandedRemaining = _expandInlineIncludes(
        remaining,
        moduleDirectory,
        workspaceRoot,
        allowInlineIncludeKey: false,
      );
      return _mergeConfigValues(merged, expandedRemaining);
    }

    final result = <String, dynamic>{};
    map.forEach((key, dynamic entry) {
      result[key] = _expandInlineIncludes(
        entry,
        moduleDirectory,
        workspaceRoot,
        allowInlineIncludeKey: false,
      );
    });
    return result;
  }

  if (value is List) {
    return value
        .map(
          (entry) => _expandInlineIncludes(
            entry,
            moduleDirectory,
            workspaceRoot,
            allowInlineIncludeKey: false,
          ),
        )
        .toList();
  }

  return value;
}

List<dynamic> _loadInlineIncludeValues(
  dynamic includeValue,
  Directory moduleDirectory,
  Directory workspaceRoot,
) {
  final items = includeValue is List ? includeValue : [includeValue];
  final resolved = <dynamic>[];
  for (final entry in items) {
    resolved.add(
      _loadInlineIncludeEntry(
        entry,
        moduleDirectory,
        workspaceRoot,
      ),
    );
  }
  return resolved;
}

dynamic _loadInlineIncludeEntry(
  dynamic entry,
  Directory moduleDirectory,
  Directory workspaceRoot,
) {
  if (entry == null) {
    throw FormatException('Empty include entry in ${moduleDirectory.path}');
  }
  if (entry is String) {
    final file = _resolveIncludeFile(entry, moduleDirectory, workspaceRoot);
    final content = file.readAsStringSync();
    final node = loadYamlNode(content, sourceUrl: file.uri);
    final includeStack = <String>{file.path};
    return _convertYamlNode(node, file, includeStack, workspaceRoot);
  }
  if (entry is Map) {
    final includePath = entry['path'] ?? entry['include'];
    if (includePath == null) {
      throw FormatException('Include entry map must contain `path` in ${moduleDirectory.path}');
    }
    final raw = _parseRawFlag(entry['raw']);
    final file = _resolveIncludeFile(includePath.toString(), moduleDirectory, workspaceRoot);
    if (raw) {
      return file.readAsStringSync();
    }
    final content = file.readAsStringSync();
    final node = loadYamlNode(content, sourceUrl: file.uri);
    final includeStack = <String>{file.path};
    return _convertYamlNode(node, file, includeStack, workspaceRoot);
  }
  if (entry is List) {
    return entry
        .map(
          (item) => _loadInlineIncludeEntry(
            item,
            moduleDirectory,
            workspaceRoot,
          ),
        )
        .toList();
  }
  return entry;
}

dynamic _mergeConfigValues(dynamic base, dynamic update) {
  if (base == null) return update;
  if (update == null) return base;
  if (base is Map || update is Map) {
    final baseMap = _asStringKeyedMap(base);
    final updateMap = _asStringKeyedMap(update);
    return _mergeConfigMaps(baseMap, updateMap);
  }
  throw FormatException(
    'Include merges must involve map values. Got ${base.runtimeType} and ${update.runtimeType}.',
  );
}

Map<String, dynamic> _asStringKeyedMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }
  if (value is Map) {
    final result = <String, dynamic>{};
    value.forEach((dynamic key, dynamic entry) {
      final normalizedKey = key?.toString();
      if (normalizedKey == null || normalizedKey.isEmpty) {
        return;
      }
      result[normalizedKey] = entry;
    });
    return result;
  }
  throw FormatException('Expected map, got ${value.runtimeType}');
}

Map<String, dynamic> _mergeConfigMaps(
  Map<String, dynamic> base,
  Map<String, dynamic> update,
) {
  final result = <String, dynamic>{}..addAll(base);
  update.forEach((key, value) {
    final existing = result[key];
    if (existing is Map && value is Map) {
      result[key] = _mergeConfigMaps(
        _asStringKeyedMap(existing),
        _asStringKeyedMap(value),
      );
    } else {
      result[key] = value;
    }
  });
  return result;
}

File _resolveIncludeFile(
  String includePath,
  Directory relativeTo,
  Directory workspaceRoot,
) {
  final cleaned = includePath.trim();
  final candidates = <String>[];
  if (path.isAbsolute(cleaned)) {
    candidates.add(path.normalize(cleaned));
  } else {
    candidates
      ..add(path.normalize(path.join(relativeTo.path, cleaned)))
      ..add(path.normalize(path.join(workspaceRoot.path, cleaned)));
  }
  for (final candidate in candidates) {
    final file = File(candidate);
    if (file.existsSync()) {
      return file;
    }
  }
  throw FormatException(
    'Include target $includePath not found relative to ${relativeTo.path}',
  );
}

Map<String, Set<String>> _parseLayerPackages(Map<String, dynamic> featureLayers) {
  final allowances = <String, Set<String>>{};

  void addPackages(String layer, Iterable<String> packages) {
    final normalizedLayer = layer.trim().toLowerCase();
    if (normalizedLayer.isEmpty) {
      return;
    }
    final packageSet = packages.map((pkg) => pkg.trim().toLowerCase()).where((pkg) => pkg.isNotEmpty);
    if (packageSet.isEmpty) {
      return;
    }
    allowances.putIfAbsent(normalizedLayer, () => <String>{}).addAll(packageSet);
  }

  final allowBlock = featureLayers['allow'];
  if (allowBlock is Map) {
    _asStringKeyedMap(allowBlock).forEach((layer, dynamic packages) {
      addPackages(layer, _parsePackageList(packages));
    });
  }

  final packageVisibility = featureLayers['package_visibility'];
  if (packageVisibility is Map) {
    _asStringKeyedMap(packageVisibility).forEach((packageName, dynamic layersValue) {
      final layers = _parseLayerList(layersValue);
      if (layers.isEmpty) {
        return;
      }
      final normalizedPackage = packageName.trim().toLowerCase();
      if (normalizedPackage.isEmpty) {
        return;
      }
      for (final layer in layers) {
        allowances.putIfAbsent(layer, () => <String>{}).add(normalizedPackage);
      }
    });
  }

  featureLayers.forEach((key, value) {
    if (key == 'allow' || key == 'package_visibility') {
      return;
    }
    final packages = _parsePackageList(value);
    if (packages.isEmpty) {
      return;
    }
    addPackages(key, packages);
  });

  return allowances;
}

Set<String> _parsePackageList(dynamic value) {
  final packages = <String>{};
  if (value is List) {
    for (final entry in value) {
      final pkg = entry?.toString().trim();
      if (pkg == null || pkg.isEmpty) {
        continue;
      }
      packages.add(pkg);
    }
    return packages;
  }
  if (value is String) {
    final pkg = value.trim();
    if (pkg.isNotEmpty) {
      packages.add(pkg);
    }
    return packages;
  }
  if (value is Map && value.containsKey('packages')) {
    return _parsePackageList(value['packages']);
  }
  return packages;
}

Set<String> _parseLayerList(dynamic value) {
  if (value is List) {
    final result = <String>{};
    for (final entry in value) {
      final layer = entry?.toString().trim().toLowerCase();
      if (layer == null || layer.isEmpty) {
        continue;
      }
      result.add(layer);
    }
    return result;
  }
  final single = value?.toString().trim().toLowerCase();
  if (single == null || single.isEmpty) {
    return <String>{};
  }
  return {single};
}
