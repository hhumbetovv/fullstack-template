import 'dart:io';

import 'context.dart';
import 'logging.dart';
import 'options.dart';
import 'yaml_utils.dart';

class GraphConfig {
  GraphConfig({
    required this.path,
    required this.title,
    required this.primaryModules,
    required this.section,
    this.description,
    this.includeDependencies = true,
    this.highlightPrimary = true,
  });

  final String path;
  final String title;
  final Set<String> primaryModules;
  final String section;
  final String? description;
  final bool includeDependencies;
  final bool highlightPrimary;
}

String? classifyModule(String moduleName) {
  if (moduleName.startsWith('common_') || moduleName.contains('_common')) {
    return 'common';
  }
  if (moduleName.startsWith('core_') || moduleName.contains('_core')) {
    return 'core';
  }
  if (moduleName.startsWith('ui_') || moduleName.contains('_ui')) {
    return 'ui';
  }
  if (moduleName.contains('_presentation') || moduleName.endsWith('_ui')) {
    return 'presentation';
  }
  if (moduleName.contains('_domain') || moduleName.contains('_business')) {
    return 'domain';
  }
  if (moduleName.contains('_data') || moduleName.contains('_repository')) {
    return 'data';
  }

  return null;
}

String moduleEdgeColor(String moduleName) {
  switch (classifyModule(moduleName)) {
    case 'presentation':
      return '#0277bd';
    case 'domain':
      return '#7b1fa2';
    case 'data':
      return '#2e7d32';
    case 'ui':
      return '#f57c00';
    case 'common':
      return '#c2185b';
    case 'core':
      return '#00695c';
    default:
      return '#546e7a';
  }
}

Future<bool> writeGraphFile(
  GraphConfig config,
  Set<String> modulesWithUnusedDeps,
) async {
  final nodes = <String>{...config.primaryModules};

  if (config.includeDependencies) {
    for (final module in config.primaryModules) {
      nodes.addAll(state.allModuleDependencies[module] ?? <String>{});
    }
  }

  nodes.removeWhere((module) => !state.allModulePaths.containsKey(module));

  if (nodes.isEmpty) {
    return false;
  }

  final orderedModules = nodes.toList()
    ..sort((a, b) {
      final levelA = state.moduleBuildLevel[a] ?? 999;
      final levelB = state.moduleBuildLevel[b] ?? 999;
      if (levelA != levelB) return levelA.compareTo(levelB);
      return a.compareTo(b);
    });

  final content = StringBuffer()
    ..writeln('# ${config.title}')
    ..writeln('');

  if (config.description != null && config.description!.isNotEmpty) {
    content
      ..writeln(config.description)
      ..writeln('');
  }

  content
    ..writeln('```mermaid')
    ..writeln('graph LR');

  final presentClasses = <String>{};
  var focusUsed = false;

  void writeNode(String moduleName) {
    final level = state.moduleBuildLevel[moduleName];
    final waveLabel = level != null ? '🌊 Wave $level' : '🚫 No build';
    content.writeln('    $moduleName["$moduleName\\n$waveLabel"]');

    final category = classifyModule(moduleName);
    if (category != null) {
      content.writeln('    $moduleName:::$category');
      presentClasses.add(category);
    }
    if (modulesWithUnusedDeps.contains(moduleName)) {
      content.writeln('    class $moduleName unused;');
      presentClasses.add('unused');
    }
    if (config.highlightPrimary && config.primaryModules.contains(moduleName)) {
      content.writeln('    class $moduleName focus;');
      focusUsed = true;
    }
  }

  for (final moduleName in orderedModules) {
    writeNode(moduleName);
  }

  content
    ..writeln('')
    ..writeln('    %% Edge styling')
    ..writeln(
      '    linkStyle default stroke:#b0bec5,stroke-width:1,opacity:0.35',
    );

  final edgeColorMap = <String, List<int>>{};
  var edgeIndex = 0;

  final dependencyOrder = orderedModules.toList()..sort();
  for (final moduleName in dependencyOrder) {
    final deps = state.allModuleDependencies[moduleName];
    if (deps == null || deps.isEmpty) {
      continue;
    }

    final filteredDeps = deps.where(nodes.contains).toList()..sort();

    for (final dep in filteredDeps) {
      final colour = moduleEdgeColor(dep);
      content.writeln('    $dep --> $moduleName');
      edgeColorMap.putIfAbsent(colour, () => <int>[]).add(edgeIndex);
      edgeIndex++;
    }
  }

  if (edgeColorMap.isNotEmpty) {
    content.writeln('');
    final styleEntries = edgeColorMap.entries.toList()..sort((a, b) => a.value.first.compareTo(b.value.first));
    for (final entry in styleEntries) {
      final indices = entry.value..sort();
      content.writeln(
        '    linkStyle ${indices.join(',')} stroke:${entry.key},stroke-width:1.9,opacity:0.9',
      );
    }
  }

  content.writeln('');

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
    'presentation': '    classDef presentation fill:#e1f5fe,stroke:#0277bd,stroke-width:2px,color:#000000',
    'domain': '    classDef domain fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000000',
    'data': '    classDef data fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px,color:#000000',
    'ui': '    classDef ui fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000000',
    'common': '    classDef common fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000000',
    'core': '    classDef core fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000000',
    'unused': '    classDef unused fill:#ffebee,stroke:#c62828,stroke-width:2px,color:#000000',
  };

  for (final className in classOrder) {
    if (presentClasses.contains(className)) {
      content.writeln(classStyles[className]);
    }
  }

  if (focusUsed) {
    content.writeln(
      '    classDef focus fill:#fffde7,stroke:#fbc02d,stroke-width:2.5px,color:#000000',
    );
  }

  content
    ..writeln('```')
    ..writeln('');

  await File(config.path).writeAsString(content.toString());
  return true;
}

Future<Set<String>> parseDependencies(
  String pubspecPath,
  String moduleName,
  Map<String, String> knownModules,
) async {
  final dependencies = <String>{};

  try {
    final pubspec = await readPubspec(pubspecPath);
    if (pubspec == null) return dependencies;

    final deps = pubspec['dependencies'] as Map<String, dynamic>?;
    final devDeps = pubspec['dev_dependencies'] as Map<String, dynamic>?;

    void processDeps(Map<String, dynamic>? depsMap) {
      if (depsMap == null) return;

      depsMap.forEach((key, value) {
        final depName = key;

        if (!knownModules.containsKey(depName)) {
          return;
        }

        if (shouldIgnoreModule(depName)) {
          return;
        }

        dependencies.add(depName);
        Logger.debug('   Found dependency: $moduleName → $depName');
      });
    }

    processDeps(deps);
    processDeps(devDeps);
  } on Exception catch (e) {
    Logger.error('Error parsing dependencies from $pubspecPath: $e');
  }

  return dependencies;
}

Future<void> buildDependencyGraph() async {
  Logger.info('🕸️  Building dependency graph...');

  state.moduleDependencies.clear();
  state.allModuleDependencies.clear();
  state.moduleUnusedDependencies.clear();

  if (state.allModulePaths.isEmpty) {
    Logger.warning('No modules discovered for dependency analysis');
    return;
  }

  for (final entry in state.allModulePaths.entries) {
    final moduleName = entry.key;
    final modulePath = entry.value;
    final pubspecFile = '$modulePath/pubspec.yaml';

    final fullDependencies = await parseDependencies(
      pubspecFile,
      moduleName,
      state.allModulePaths,
    );
    state.allModuleDependencies[moduleName] = fullDependencies;

    if (state.modulePaths.containsKey(moduleName)) {
      final buildDependencies = fullDependencies.where(state.modulePaths.containsKey).toSet();
      state.moduleDependencies[moduleName] = buildDependencies;

      if (buildDependencies.isNotEmpty) {
        Logger.info(
          '   📦 $moduleName depends on: ${buildDependencies.join(', ')}',
        );
      } else {
        Logger.verbose(
          '   📦 $moduleName has no internal build_runner dependencies',
        );
      }

      if (state.verbose) {
        final additionalDeps = fullDependencies.difference(buildDependencies);
        if (additionalDeps.isNotEmpty) {
          Logger.verbose(
            '   ↳ Additional non-build_runner deps: ${additionalDeps.join(', ')}',
          );
        }
      }
    } else if (state.verbose) {
      if (fullDependencies.isNotEmpty) {
        Logger.verbose(
          '   🧩 $moduleName (graph) depends on: ${fullDependencies.join(', ')}',
        );
      } else {
        Logger.verbose(
          '   🧩 $moduleName (graph) has no internal dependencies',
        );
      }
    }
  }

  if (state.verbose) {
    Logger.info('📊 Dependency Summary:');
    for (final entry in state.moduleDependencies.entries) {
      Logger.verbose(
        '${entry.key}: ${entry.value.length} build_runner dependencies',
      );
    }
  }
}

Future<Set<String>> _collectImportedPackages(String moduleName) async {
  final modulePath = state.allModulePaths[moduleName];
  if (modulePath == null) {
    return <String>{};
  }

  final importRegex = RegExp(
    "(?:import|export)\\s+['\"]package:([^/'\"]+)",
    multiLine: true,
  );
  final collected = <String>{};
  final directories = <String>['lib', 'src', 'bin', 'test', 'tool'];

  for (final dirName in directories) {
    final dir = Directory('$modulePath/$dirName');
    if (!dir.existsSync()) {
      continue;
    }

    try {
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }

        try {
          final content = await entity.readAsString();
          for (final match in importRegex.allMatches(content)) {
            final packageName = match.group(1);
            if (packageName != null && packageName.isNotEmpty) {
              collected.add(packageName);
            }
          }
        } on Exception catch (e) {
          Logger.debug('Error reading ${entity.path}: $e');
        }
      }
    } on Exception catch (e) {
      Logger.debug('Error scanning $modulePath/$dirName: $e');
    }
  }

  return collected;
}

Future<void> analyzeUnusedModuleDependencies() async {
  Logger.info('🧹 Analyzing unused module dependencies...');

  state.moduleUnusedDependencies.clear();

  for (final entry in state.allModuleDependencies.entries) {
    final moduleName = entry.key;
    final declaredDeps = entry.value;

    if (declaredDeps.isEmpty) {
      continue;
    }

    final importedPackages = await _collectImportedPackages(moduleName);
    final unused = declaredDeps.difference(importedPackages);

    if (unused.isNotEmpty) {
      state.moduleUnusedDependencies[moduleName] = unused;
      Logger.info('   🚫 $moduleName unused: ${unused.join(', ')}');
    } else if (state.verbose) {
      Logger.verbose('   ✅ $moduleName uses all declared modules');
    }
  }

  if (state.moduleUnusedDependencies.isEmpty) {
    Logger.success('No unused module dependencies detected.');
  }
}

void calculateBuildLevels() {
  Logger.info('🌊 Calculating build waves...');

  final inDegree = <String, int>{};
  final tempInDegree = <String, int>{};

  for (final moduleName in state.modulePaths.keys) {
    inDegree[moduleName] = 0;
  }

  for (final entry in state.moduleDependencies.entries) {
    for (final _ in entry.value) {
      inDegree[entry.key] = (inDegree[entry.key] ?? 0) + 1;
    }
  }

  tempInDegree.addAll(inDegree);

  var level = 0;
  var processed = 0;
  final total = state.modulePaths.length;

  while (processed < total) {
    final waveModules = <String>[];

    for (final entry in tempInDegree.entries) {
      if (entry.value == 0 && !state.moduleBuildLevel.containsKey(entry.key)) {
        state.moduleBuildLevel[entry.key] = level;
        waveModules.add(entry.key);
        processed++;
      }
    }

    if (waveModules.isEmpty && processed < total) {
      Logger.error('Circular dependency detected or disconnected modules!');
      for (final entry in tempInDegree.entries) {
        if (!state.moduleBuildLevel.containsKey(entry.key)) {
          Logger.error(
            '   Stuck module: ${entry.key} (in-degree: ${entry.value})',
          );
        }
      }
      throw Exception('Circular dependency detected');
    }

    if (waveModules.isNotEmpty) {
      Logger.info('   🌊 Wave $level: ${waveModules.join(' ')}');
    }

    for (final module in waveModules) {
      for (final entry in state.moduleDependencies.entries) {
        if (entry.value.contains(module)) {
          tempInDegree[entry.key] = (tempInDegree[entry.key] ?? 0) - 1;
        }
      }
    }

    level++;
  }

  Logger.success('Build waves calculated: $level waves total');
}

Future<void> generateMermaidGraph() async {
  Logger.info('📊 Generating dependency graph (build_graph.md)...');

  final modulesWithUnusedDeps = state.moduleUnusedDependencies.keys.toSet();

  final graphDir = Directory('build_info');
  if (!graphDir.existsSync()) {
    graphDir.createSync(recursive: true);
  }
  for (final entity in graphDir.listSync()) {
    if (entity is File && entity.path.endsWith('.md')) {
      entity.deleteSync();
    }
  }

  final allModules = state.allModulePaths.keys.toSet();

  var maxWave = -1;
  for (final level in state.moduleBuildLevel.values) {
    if (level > maxWave) {
      maxWave = level;
    }
  }

  final graphs = <GraphConfig>[
    GraphConfig(
      path: 'build_info/graph_all.md',
      title: 'Full Workspace Module Graph',
      primaryModules: Set<String>.from(allModules),
      section: 'overview',
      description: 'Complete dependency graph sorted by build waves.',
      highlightPrimary: false,
    ),
  ];

  for (var wave = 0; wave <= maxWave; wave++) {
    final waveModules = state.moduleBuildLevel.entries
        .where((entry) => entry.value == wave)
        .map((entry) => entry.key)
        .toSet();
    if (waveModules.isEmpty) continue;
    graphs.add(
      GraphConfig(
        path: 'build_info/graph_wave_$wave.md',
        title: 'Wave $wave Dependency Graph',
        primaryModules: waveModules,
        section: 'waves',
        description: 'Modules scheduled in wave $wave with their workspace dependencies.',
      ),
    );
  }

  const categoryLabels = <String, String>{
    'common': 'Common Layer',
    'core': 'Core Layer',
    'ui': 'UI Layer',
    'domain': 'Domain Layer',
    'data': 'Data Layer',
    'presentation': 'Presentation Layer',
  };

  categoryLabels.forEach((category, label) {
    final modules = allModules.where((module) => classifyModule(module) == category).toSet();
    if (modules.isEmpty) return;
    graphs.add(
      GraphConfig(
        path: 'build_info/graph_layer_$category.md',
        title: '$label Graph',
        primaryModules: modules,
        section: 'layers',
        description: '$label modules with their workspace dependencies.',
      ),
    );
  });

  final featureGroups = <String, bool Function(String)>{
    'auth': (name) => name.startsWith('auth_'),
    'session': (name) => name.startsWith('session_'),
    'campaign': (name) => name.startsWith('campaign_'),
    'qr_scan': (name) => name.startsWith('qr_scan_'),
    'main': (name) => name.startsWith('main_') || name.startsWith('home_') || name.startsWith('profile_'),
    'global': (name) => name.contains('console') || name.contains('info'),
    'splash': (name) => name.startsWith('splash_'),
  };

  featureGroups.forEach((key, matcher) {
    final modules = allModules.where(matcher).toSet();
    if (modules.isEmpty) return;
    graphs.add(
      GraphConfig(
        path: 'build_info/graph_feature_$key.md',
        title: '${key.replaceAll('_', ' ').toUpperCase()} Feature Graph',
        primaryModules: modules,
        section: 'features',
        description: '${key.replaceAll('_', ' ').toUpperCase()} feature modules with their dependencies.',
      ),
    );
  });

  final generatedGraphs = <GraphConfig>[];
  for (final graph in graphs) {
    final wrote = await writeGraphFile(graph, modulesWithUnusedDeps);
    if (wrote) {
      generatedGraphs.add(graph);
    }
  }

  final totalModules = state.allModulePaths.length;
  var totalDependencies = 0;
  for (final deps in state.allModuleDependencies.values) {
    totalDependencies += deps.length;
  }

  final waveCounts = <int, int>{};
  for (final entry in state.moduleBuildLevel.entries) {
    if (!state.modulePaths.containsKey(entry.key)) continue;
    waveCounts[entry.value] = (waveCounts[entry.value] ?? 0) + 1;
  }

  var peakConcurrent = 0;
  for (final count in waveCounts.values) {
    if (count > peakConcurrent) {
      peakConcurrent = count;
    }
  }

  final summary = StringBuffer()
    ..writeln('# Workspace Build Overview')
    ..writeln('')
    ..writeln('## Quick Stats')
    ..writeln('')
    ..writeln('- **Total Modules**: $totalModules')
    ..writeln('- **Modules With build_runner**: ${state.modulePaths.length}')
    ..writeln(
      '- **Modules Without build_runner**: ${totalModules - state.modulePaths.length}',
    )
    ..writeln('- **Total Dependencies**: $totalDependencies')
    ..writeln(
      '- **Average Dependencies**: ${totalModules > 0 ? (totalDependencies / totalModules).toStringAsFixed(2) : '0'}',
    )
    ..writeln('- **Peak Concurrent Modules**: $peakConcurrent')
    ..writeln('- **Configured Parallel Limit**: ${state.maxParallelBuilds}')
    ..writeln('');

  if (generatedGraphs.isNotEmpty) {
    summary
      ..writeln('## Graph Index')
      ..writeln('');

    const sectionTitles = <String, String>{
      'overview': 'Overview',
      'waves': 'Build Waves',
      'layers': 'Architecture Layers',
      'features': 'Feature Areas',
    };

    for (final section in ['overview', 'waves', 'layers', 'features']) {
      final items = generatedGraphs.where((graph) => graph.section == section).toList()
        ..sort((a, b) => a.title.compareTo(b.title));
      if (items.isEmpty) continue;

      summary
        ..writeln('### ${sectionTitles[section] ?? section}')
        ..writeln('');

      for (final graph in items) {
        final description = (graph.description != null && graph.description!.isNotEmpty)
            ? ' — ${graph.description}'
            : '';
        summary.writeln('- [${graph.title}](${graph.path})$description');
      }

      summary.writeln('');
    }
  }

  summary
    ..writeln('## Build Waves')
    ..writeln('')
    ..writeln(
      'The modules requiring build_runner will be built in the following waves:',
    )
    ..writeln('');

  if (maxWave < 0) {
    summary.writeln('No modules require build_runner at this time.');
  } else {
    for (var level = 0; level <= maxWave; level++) {
      final waveModules =
          state.moduleBuildLevel.entries.where((entry) => entry.value == level).map((entry) => entry.key).toList()
            ..sort();

      summary
        ..writeln('')
        ..writeln('### Wave $level')
        ..writeln('');

      if (waveModules.isEmpty) {
        summary.writeln('- _(No modules scheduled in this wave)_');
        continue;
      }

      for (final module in waveModules) {
        final deps = state.moduleDependencies[module] ?? <String>{};
        if (deps.isNotEmpty) {
          final orderedDeps = deps.toList()..sort();
          summary.writeln(
            '- **$module** → depends on: ${orderedDeps.join(', ')}',
          );
        } else {
          summary.writeln('- **$module** → no dependencies');
        }
      }
    }
  }

  if (state.moduleUnusedDependencies.isNotEmpty) {
    summary
      ..writeln('')
      ..writeln('## Unused Module Dependencies')
      ..writeln('')
      ..writeln(
        'The following modules declare workspace dependencies that are never imported:',
      )
      ..writeln('');

    final sortedEntries = state.moduleUnusedDependencies.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in sortedEntries) {
      final unused = entry.value.toList()..sort();
      summary.writeln('- **${entry.key}** → ${unused.join(', ')}');
    }
  }

  summary
    ..writeln('')
    ..writeln('_Detailed graphs are available under the `build_info/` directory._')
    ..writeln('');

  await File('build_graph.md').writeAsString(summary.toString());
  Logger.success('Dependency graph summary saved to build_graph.md');
  Logger.info('Supplementary graph files generated in build_info/.');
}

void topologicalSort() {
  Logger.info('🔄 Calculating optimal build order...');

  final inDegree = <String, int>{};
  final adjList = <String, Set<String>>{};

  for (final moduleName in state.modulePaths.keys) {
    inDegree[moduleName] = 0;
    adjList[moduleName] = <String>{};
  }

  for (final entry in state.moduleDependencies.entries) {
    final moduleName = entry.key;
    final dependencies = entry.value;

    for (final dep in dependencies) {
      if (state.modulePaths.containsKey(dep)) {
        adjList[dep]!.add(moduleName);
        inDegree[moduleName] = (inDegree[moduleName] ?? 0) + 1;
      } else {
        Logger.warning('Unknown dependency: $dep for module $moduleName');
      }
    }
  }

  Logger.debug('In-degrees calculated:');
  if (state.verbose) {
    for (final entry in inDegree.entries) {
      Logger.debug('   ${entry.key}: ${entry.value}');
    }
  }

  final queue = <String>[];
  for (final entry in inDegree.entries) {
    if (entry.value == 0) {
      queue.add(entry.key);
      Logger.debug('Initial queue member: ${entry.key}');
    }
  }

  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    state.buildOrder.add(current);

    Logger.debug('Processing: $current');

    for (final dependent in adjList[current]!) {
      final newDegree = (inDegree[dependent] ?? 0) - 1;
      inDegree[dependent] = newDegree;
      Logger.debug('   Updated $dependent in-degree to $newDegree');

      if (newDegree == 0) {
        queue.add(dependent);
        Logger.debug('   Added $dependent to queue');
      }
    }
  }

  if (state.buildOrder.length != state.modulePaths.length) {
    Logger.error('Circular dependency detected! Cannot determine build order.');
    Logger.error(
      'Processed: ${state.buildOrder.length} out of ${state.modulePaths.length} modules',
    );

    for (final moduleName in state.modulePaths.keys) {
      if (!state.buildOrder.contains(moduleName)) {
        Logger.error(
          '   Stuck module: $moduleName (remaining in-degree: ${inDegree[moduleName]})',
        );
        final deps = state.moduleDependencies[moduleName] ?? <String>{};
        Logger.error('   Dependencies: ${deps.join(' ')}');
      }
    }

    throw SmartBuildException('', exitCode: 1);
  }

  Logger.success('Build order determined: ${state.buildOrder.length} modules');
  if (state.verbose) {
    Logger.info('Build order:');
    for (var i = 0; i < state.buildOrder.length; i++) {
      Logger.verbose('${i + 1}. ${state.buildOrder[i]}');
    }
  }
}

void showBuildPlan() {
  Logger.info('📋 Build Plan');
  Logger.info('═════════════');

  var maxWave = 0;
  for (final wave in state.moduleBuildLevel.values) {
    if (wave > maxWave) {
      maxWave = wave;
    }
  }

  for (var wave = 0; wave <= maxWave; wave++) {
    log('');
    Logger.info('🌊 Wave $wave (can run in parallel):');

    for (final moduleName in state.buildOrder) {
      if (state.moduleBuildLevel[moduleName] == wave) {
        final deps = state.moduleDependencies[moduleName] ?? <String>{};
        if (deps.isNotEmpty) {
          Logger.info('   • $moduleName (depends on: ${deps.join(', ')})');
        } else {
          Logger.info('   • $moduleName (no dependencies)');
        }
      }
    }
  }
  log('');
}
