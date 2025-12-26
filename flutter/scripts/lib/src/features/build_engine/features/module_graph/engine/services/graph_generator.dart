// ignore_for_file: cascade_invocations, avoid_single_cascade_in_expression_statements

import 'dart:io';

import 'package:common_tooling/tooling.dart'
    show normalizeLineEndings, preferredLineEndingForContent;
import 'package:scripts/src/core/config/scripts_config.dart';
import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/features/build_engine/domain/models/build_state.dart';
import 'package:scripts/src/features/build_engine/domain/models/graph_config.dart'
    show classifyModule;
import 'package:scripts/src/features/build_engine/domain/models/graph_report.dart';

class GraphGenerator {
  const GraphGenerator();

  Future<GraphReport> generate(
    BuildState state, {
    bool quiet = false,
  }) async {
    const moduleGraphFile = ModuleGraphConfig.moduleGraphFile;
    const overviewFile = ModuleGraphConfig.overviewFile;
    if (!quiet) {
      Logger.info('📊 Generating dependency graph ($overviewFile)...');
    }

    final modulesWithUnusedDeps = state.moduleUnusedDependencies.keys.toSet();
    final modulesWithUnusedPackages = state.moduleUnusedPackages.keys.toSet();

    var maxWave = -1;
    for (final level in state.moduleBuildLevel.values) {
      if (level > maxWave) {
        maxWave = level;
      }
    }

    final totalDependencies = state.allModuleDependencies.values.fold<int>(
      0,
      (sum, deps) => sum + deps.length,
    );

    final sections = <_GraphSection>[
      _buildBaseToFeatureSection(state, modulesWithUnusedDeps),
      _buildFeaturesOnlySection(state, modulesWithUnusedDeps),
      _buildWaveGroupedSection(state, maxWave, modulesWithUnusedDeps),
      _buildLayerGroupedSection(state, modulesWithUnusedDeps),
    ];

    await _writeCombinedGraphFile(
      sections,
      moduleGraphFile,
    );

    final outputs = <GraphFile>[
      const GraphFile(path: moduleGraphFile, title: 'Module Graphs'),
    ];

    await _writeBuildGraphOverview(
      state: state,
      totalDependencies: totalDependencies,
      modulesWithUnused: modulesWithUnusedDeps,
      modulesWithUnusedPackages: modulesWithUnusedPackages,
      maxWave: maxWave,
      sections: sections,
      overviewPath: overviewFile,
      moduleGraphPath: moduleGraphFile,
    );

    outputs.add(
      const GraphFile(
        path: overviewFile,
        title: 'Workspace Build Overview',
      ),
    );

    return GraphReport(
      summary: GraphSummary(
        totalModules: state.allModulePaths.length,
        totalDependencies: totalDependencies,
        modulesWithUnused: modulesWithUnusedDeps,
      ),
      outputs: outputs,
    );
  }
}

_GraphSection _buildBaseToFeatureSection(
  BuildState state,
  Set<String> modulesWithUnused,
) {
  final buffer = StringBuffer()
    ..writeln('```mermaid')
    ..writeln('graph LR');

  final featureModules = _featureModules(state);
  final modulePaths = state.allModulePaths;
  final baseModules =
      modulePaths.keys
          .where((module) => !featureModules.contains(module))
          .toList()
        ..sort();

  final styles = _GraphStyleTracker();
  for (final module in baseModules) {
    final id = _nodeId(module);
    buffer..writeln('    $id["$module"]');
    _applyModuleStyling(
      buffer,
      styles,
      module,
      modulesWithUnused,
    );
  }

  final featuresNodeId = _nodeId('features');
  final appId = state.allModulePaths.containsKey('app') ? _nodeId('app') : null;
  if (appId != null) {
    buffer.writeln('    class $appId feature');
    styles.markFeatureUsed();
  }

  final featureDependencySources = <String>{};
  for (final entry in state.allModuleDependencies.entries) {
    final source = entry.key;
    if (featureModules.contains(source)) {
      for (final target in entry.value) {
        if (!featureModules.contains(target) &&
            modulePaths.containsKey(target)) {
          featureDependencySources.add(target);
        }
      }
      continue;
    }
    for (final target in entry.value) {
      if (featureModules.contains(target)) {
        continue;
      }
      if (modulePaths.containsKey(target)) {
        buffer..writeln('    ${_nodeId(target)} --> ${_nodeId(source)}');
      }
    }
  }

  if (featureDependencySources.isNotEmpty) {
    buffer.writeln('    $featuresNodeId["Features"]');
    buffer.writeln('    class $featuresNodeId feature');
    styles.markFeatureUsed();

    final contributors = featureDependencySources.toList()..sort();
    for (final contributor in contributors) {
      buffer.writeln('    ${_nodeId(contributor)} --> $featuresNodeId');
    }

    if (appId != null) {
      buffer.writeln('    $featuresNodeId --> $appId');
    }
  }

  _writeClassDefinitions(buffer, styles);
  buffer
    ..writeln('```')
    ..writeln('');

  return _GraphSection(
    title: 'foundation.md',
    content: buffer.toString(),
  );
}

_GraphSection _buildFeaturesOnlySection(
  BuildState state,
  Set<String> modulesWithUnused,
) {
  final buffer = StringBuffer()
    ..writeln('```mermaid')
    ..writeln('graph LR');

  final featureModules = _featureModules(state);
  final featureList = featureModules.toList()..sort();
  final styles = _GraphStyleTracker();
  for (final module in featureList) {
    final id = _nodeId(module);
    buffer.writeln('    $id["$module"]');
    _applyModuleStyling(
      buffer,
      styles,
      module,
      modulesWithUnused,
    );
  }

  for (final entry in state.allModuleDependencies.entries) {
    final source = entry.key;
    if (!featureModules.contains(source)) continue;
    for (final target in entry.value) {
      if (!featureModules.contains(target)) continue;
      buffer..writeln('    ${_nodeId(target)} --> ${_nodeId(source)}');
    }
  }

  _writeClassDefinitions(buffer, styles);
  buffer
    ..writeln('```')
    ..writeln('');

  return _GraphSection(
    title: 'features.md',
    content: buffer.toString(),
  );
}

_GraphSection _buildWaveGroupedSection(
  BuildState state,
  int maxWave,
  Set<String> modulesWithUnused,
) {
  final buffer = StringBuffer()
    ..writeln('```mermaid')
    ..writeln('graph TB');

  final declared = <String>{};
  final styles = _GraphStyleTracker();
  final waveClusters = <String>[];
  for (var wave = 0; wave <= maxWave; wave++) {
    final modules =
        state.moduleBuildLevel.entries
            .where((entry) => entry.value == wave)
            .map((entry) => entry.key)
            .toList()
          ..sort();
    if (modules.isEmpty) continue;
    final clusterId = _nodeId('wave_cluster_$wave');
    waveClusters.add(clusterId);
    buffer.writeln('    subgraph $clusterId["Wave $wave"]');
    buffer.writeln('        direction TB');
    for (final module in modules) {
      final id = _nodeId(module);
      buffer.writeln('        $id["$module"]');
      declared.add(module);
      _applyModuleStyling(
        buffer,
        styles,
        module,
        modulesWithUnused,
        indent: '        ',
      );
    }
    buffer.writeln('    end');
  }

  for (var i = 0; i < waveClusters.length - 1; i++) {
    buffer.writeln('    ${waveClusters[i]} --> ${waveClusters[i + 1]}');
  }

  _writeClassDefinitions(buffer, styles);
  buffer
    ..writeln('```')
    ..writeln('');

  return _GraphSection(
    title: 'waves.md',
    content: buffer.toString(),
  );
}

Future<void> _writeBuildGraphOverview({
  required BuildState state,
  required int totalDependencies,
  required Set<String> modulesWithUnused,
  required Set<String> modulesWithUnusedPackages,
  required int maxWave,
  required List<_GraphSection> sections,
  required String overviewPath,
  required String moduleGraphPath,
}) async {
  final totalModules = state.allModulePaths.length;
  final buildRunnerModules = state.modulePaths.length;
  final withoutBuildRunner = totalModules - buildRunnerModules;
  final avgDependencies = totalModules == 0
      ? '0.00'
      : (totalDependencies / totalModules).toStringAsFixed(2);

  final waveModules = _collectWaveModules(state, maxWave);
  final peakConcurrent = waveModules.isEmpty
      ? 0
      : waveModules
            .map((wave) => wave.modules.length)
            .reduce((a, b) => a > b ? a : b);

  final buffer = StringBuffer()
    ..writeln('# Workspace Build Overview')
    ..writeln('')
    ..writeln('## Quick Stats')
    ..writeln('')
    ..writeln('- **Total Modules**: $totalModules')
    ..writeln('- **Modules With build_runner**: $buildRunnerModules')
    ..writeln('- **Modules Without build_runner**: $withoutBuildRunner')
    ..writeln('- **Total Dependencies**: $totalDependencies')
    ..writeln('- **Average Dependencies**: $avgDependencies')
    ..writeln('- **Peak Concurrent Modules**: $peakConcurrent')
    ..writeln('')
    ..writeln('## Graph Index')
    ..writeln('')
    ..write(_graphIndexSection(sections, moduleGraphPath))
    ..writeln('')
    ..writeln('## Build Waves')
    ..writeln('')
    ..write(_waveNarrative(state, waveModules))
    ..writeln('')
    ..writeln('## Unused Module Dependencies')
    ..writeln('')
    ..write(_unusedDependenciesSection(state, modulesWithUnused))
    ..writeln('')
    ..writeln('## Unused Packages')
    ..writeln('')
    ..write(_unusedPackagesSection(state, modulesWithUnusedPackages))
    ..writeln('')
    ..writeln(
      '_Detailed graphs are available in `$moduleGraphPath`._',
    )
    ..writeln('');
  final file = File(overviewPath);
  file.parent.createSync(recursive: true);
  await file.writeAsString(buffer.toString());
}

String _waveNarrative(BuildState state, List<_WaveDetail> waves) {
  if (waves.isEmpty) {
    return 'No build_runner modules discovered.';
  }
  final buffer = StringBuffer();
  for (final wave in waves) {
    buffer
      ..writeln('### Wave ${wave.level}')
      ..writeln('');
    for (final module in wave.modules) {
      final deps = state.moduleDependencies[module];
      if (deps == null || deps.isEmpty) {
        buffer.writeln('- **$module** → no dependencies');
      } else {
        final sorted = deps.toList()..sort();
        buffer.writeln('- **$module** → depends on: ${sorted.join(', ')}');
      }
    }
    buffer.writeln('');
  }
  return buffer.toString();
}

String _unusedDependenciesSection(
  BuildState state,
  Set<String> modulesWithUnused,
) {
  if (modulesWithUnused.isEmpty) {
    return 'None 🎉';
  }
  final buffer = StringBuffer();
  final entries =
      state.moduleUnusedDependencies.entries
          .where((entry) => modulesWithUnused.contains(entry.key))
          .toList()
        ..sort((a, b) => a.key.compareTo(b.key));
  for (final entry in entries) {
    final unused = entry.value.toList()..sort();
    buffer.writeln('- **${entry.key}** → ${unused.join(', ')}');
  }
  return buffer.toString();
}

String _unusedPackagesSection(
  BuildState state,
  Set<String> modulesWithUnused,
) {
  if (modulesWithUnused.isEmpty) {
    return 'None 🎉';
  }
  final buffer = StringBuffer();
  final entries =
      state.moduleUnusedPackages.entries
          .where((entry) => modulesWithUnused.contains(entry.key))
          .toList()
        ..sort((a, b) => a.key.compareTo(b.key));
  for (final entry in entries) {
    final unusedPackages = entry.value.toList()..sort();
    buffer.writeln('- **${entry.key}** → ${unusedPackages.join(', ')}');
  }
  return buffer.toString();
}

List<_WaveDetail> _collectWaveModules(BuildState state, int maxWave) {
  if (maxWave < 0) {
    return const <_WaveDetail>[];
  }
  final waves = <_WaveDetail>[];
  for (var wave = 0; wave <= maxWave; wave++) {
    final modules =
        state.moduleBuildLevel.entries
            .where((entry) => entry.value == wave)
            .map((entry) => entry.key)
            .toList()
          ..sort();
    if (modules.isNotEmpty) {
      waves.add(_WaveDetail(level: wave, modules: modules));
    }
  }
  return waves;
}

class _WaveDetail {
  const _WaveDetail({
    required this.level,
    required this.modules,
  });

  final int level;
  final List<String> modules;
}

class _GraphSection {
  const _GraphSection({required this.title, required this.content});

  final String title;
  final String content;
}

_GraphSection _buildLayerGroupedSection(
  BuildState state,
  Set<String> modulesWithUnused,
) {
  final buffer = StringBuffer()
    ..writeln('```mermaid')
    ..writeln('graph LR');

  final groups = _buildLayerGroups(state);
  final groupNodes = <String, String>{};
  final moduleToGroup = <String, String>{};
  final styles = _GraphStyleTracker();

  for (final entry in groups.entries) {
    final name = entry.key;
    final modules = entry.value.toList()..sort();
    if (modules.isEmpty) continue;
    final nodeId = _nodeId('group_$name');
    groupNodes[name] = nodeId;
    buffer.writeln('    $nodeId["$name"]');
    final groupClass = _classForGroup(name);
    if (groupClass != null) {
      buffer.writeln('    class $nodeId $groupClass');
      if (groupClass == 'feature') {
        styles.markFeatureUsed();
      } else {
        styles.markClass(groupClass);
      }
    }
    for (final module in modules) {
      moduleToGroup[module] = name;
    }
  }

  final renderedEdges = <String>{};
  for (final entry in state.allModuleDependencies.entries) {
    final source = entry.key;
    final targetModules = entry.value;
    final sourceGroup = moduleToGroup[source];
    if (sourceGroup == null) continue;
    for (final target in targetModules) {
      final targetGroup = moduleToGroup[target];
      if (targetGroup == null || targetGroup == sourceGroup) continue;
      final fromId = groupNodes[targetGroup];
      final toId = groupNodes[sourceGroup];
      if (fromId == null || toId == null) continue;
      final edgeKey = '$fromId->$toId';
      if (renderedEdges.add(edgeKey)) {
        buffer.writeln('    $fromId --> $toId');
      }
    }
  }

  _writeClassDefinitions(buffer, styles);
  buffer
    ..writeln('```')
    ..writeln('');

  return _GraphSection(
    title: 'layers.md',
    content: buffer.toString(),
  );
}

Set<String> _featureModules(BuildState state) => state.allModulePaths.entries
    .where((entry) => _extractFeatureSegment(entry.value) != null)
    .map((entry) => entry.key)
    .toSet();

bool _isFeatureModule(BuildState state, String moduleName) =>
    _extractFeatureSegment(state.allModulePaths[moduleName] ?? '') != null;

Map<String, Set<String>> _groupModulesByFeature(BuildState state) {
  final groups = <String, Set<String>>{};
  for (final entry in state.allModulePaths.entries) {
    final feature = _extractFeatureSegment(entry.value);
    if (feature == null) continue;
    groups.putIfAbsent(feature, () => <String>{}).add(entry.key);
  }
  return groups;
}

Map<String, Set<String>> _buildLayerGroups(BuildState state) {
  final groups = <String, Set<String>>{
    'Core Layer': <String>{},
    'Common Layer': <String>{},
    'UI Layer': <String>{},
    'Data Layer': <String>{},
    'Domain Layer': <String>{},
  };

  for (final entry in state.allModulePaths.entries) {
    final module = entry.key;
    if (_isFeatureModule(state, module)) {
      continue;
    }
    final category = classifyModule(module);
    if (category == null) continue;
    if (category == 'core') {
      groups['Core Layer']!.add(module);
    } else if (category == 'common') {
      groups['Common Layer']!.add(module);
    } else if (category == 'ui') {
      groups['UI Layer']!.add(module);
    } else if (category == 'data') {
      groups['Data Layer']!.add(module);
    } else if (category == 'domain') {
      groups['Domain Layer']!.add(module);
    }
  }

  final featureGroups = _groupModulesByFeature(state);
  for (final entry in featureGroups.entries) {
    groups['Feature: ${_titleCase(entry.key)}'] = entry.value;
  }

  return groups;
}

const Map<String, String> _sectionDescriptions = <String, String>{
  'foundation.md': 'Highlights how shared modules feed feature delivery',
  'features.md': 'Focuses purely on feature-layer dependencies',
  'waves.md': 'Visualizes build waves from top to bottom',
  'layers.md': 'Clusters modules by architectural tier and feature area',
};

Future<void> _writeCombinedGraphFile(
  List<_GraphSection> sections,
  String outputPath,
) async {
  final buffer = StringBuffer()
    ..writeln('# Module Graphs')
    ..writeln('');

  for (final section in sections) {
    buffer
      ..writeln('## ${section.title}')
      ..writeln('')
      ..write(section.content.trimRight())
      ..writeln('')
      ..writeln('');
  }

  final content = buffer.toString().trimRight();
  final file = File(outputPath);
  file.parent.createSync(recursive: true);
  String? existing;
  if (file.existsSync()) {
    existing = await file.readAsString();
  }
  final normalized = normalizeLineEndings(
    '$content\n',
    preferredLineEnding: preferredLineEndingForContent(existing),
  );
  await file.writeAsString(normalized);
}

String? _classForGroup(String groupName) {
  if (groupName.startsWith('Feature:')) {
    return 'feature';
  }
  if (groupName.startsWith('Core')) return 'core';
  if (groupName.startsWith('Common')) return 'common';
  if (groupName.startsWith('UI')) return 'ui';
  if (groupName.startsWith('Data')) return 'data';
  if (groupName.startsWith('Domain')) return 'domain';
  return null;
}

String? _extractFeatureSegment(String path) {
  final normalized = path.replaceFirst(RegExp(r'^\./'), '');
  final segments = normalized
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (segments.isEmpty || segments.first != 'feature') {
    return null;
  }

  final lastFeatureIndex = segments.lastIndexOf('feature');
  if (lastFeatureIndex == -1 || lastFeatureIndex + 1 >= segments.length) {
    return null;
  }
  return segments[lastFeatureIndex + 1];
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  final parts = value
      .split(RegExp('[^a-zA-Z0-9]+'))
      .where((part) => part.isNotEmpty);
  return parts
      .map(
        (part) =>
            part.substring(0, 1).toUpperCase() +
            part.substring(1).toLowerCase(),
      )
      .join(' ');
}

String _nodeId(String moduleName) =>
    moduleName.replaceAll(RegExp('[^a-zA-Z0-9_]'), '_');

class _GraphStyleTracker {
  final Set<String> usedClasses = <String>{};
  bool featureClassUsed = false;

  void markClass(String className) => usedClasses.add(className);

  void markFeatureUsed() => featureClassUsed = true;
}

void _applyModuleStyling(
  StringBuffer buffer,
  _GraphStyleTracker tracker,
  String module,
  Set<String> modulesWithUnused, {
  String indent = '    ',
}) {
  final className = classifyModule(module);
  final id = _nodeId(module);
  if (className != null) {
    buffer.writeln('$indent$id:::$className');
    tracker.markClass(className);
  }
  if (modulesWithUnused.contains(module)) {
    buffer.writeln('${indent}class $id unused');
    tracker.markClass('unused');
  }
}

void _writeClassDefinitions(StringBuffer buffer, _GraphStyleTracker tracker) {
  if (tracker.usedClasses.isEmpty && !tracker.featureClassUsed) {
    return;
  }

  buffer.writeln('');
  const classOrder = <String>[
    'presentation',
    'domain',
    'data',
    'ui',
    'common',
    'core',
    'unused',
  ];
  const classStyles = <String, String>{
    'presentation':
        '    classDef presentation fill:#e1f5fe,stroke:#0277bd,stroke-width:2px,color:#000000;',
    'domain':
        '    classDef domain fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000000;',
    'data':
        '    classDef data fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px,color:#000000;',
    'ui':
        '    classDef ui fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000000;',
    'common':
        '    classDef common fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000000;',
    'core':
        '    classDef core fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000000;',
    'unused':
        '    classDef unused fill:#ffebee,stroke:#c62828,stroke-width:2px,color:#000000;',
  };

  for (final className in classOrder) {
    if (tracker.usedClasses.contains(className)) {
      final definition = classStyles[className];
      if (definition != null) {
        buffer.writeln(definition);
      }
    }
  }

  if (tracker.featureClassUsed) {
    buffer.writeln(
      '    classDef feature fill:#f6d186,stroke:#c77d39,color:#1b1b1b;',
    );
  }
}

String _graphIndexSection(
  List<_GraphSection> sections,
  String moduleGraphPath,
) {
  final buffer = StringBuffer();
  for (final section in sections) {
    final description = _sectionDescriptions[section.title];
    if (description == null) continue;
    final anchor = _anchorForSection(section.title);
    buffer..writeln(
      '- [${section.title}]($moduleGraphPath#$anchor) — $description.',
    );
  }
  return buffer.toString();
}

String _anchorForSection(String title) {
  final lower = title.toLowerCase();
  final removedPunctuation = lower.replaceAll(RegExp('[^a-z0-9 ]+'), '');
  final dasherized = removedPunctuation.trim().replaceAll(RegExp(' +'), '-');
  return dasherized;
}
