import 'dart:io';

import 'context.dart';
import 'logging.dart';
import 'options.dart';
import 'yaml_utils.dart';

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

  final content = StringBuffer()
    ..writeln('# Flutter Module Dependency Graph')
    ..writeln('')
    ..writeln('## Visual Representation')
    ..writeln('')
    ..writeln('```mermaid')
    ..writeln('graph LR');

  final modulesWithUnusedDeps = state.moduleUnusedDependencies.keys.toSet();

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

  void writeNode(String moduleName) {
    final level = state.moduleBuildLevel[moduleName];
    final waveLabel = level != null ? '🌊 Wave $level' : '🚫 No build';
    content.writeln('    $moduleName["$moduleName\n$waveLabel"]');

    final clazz = classifyModule(moduleName);
    if (clazz != null) {
      content.writeln('    $moduleName:::$clazz');
    }
    if (modulesWithUnusedDeps.contains(moduleName)) {
      content.writeln('    class $moduleName unused;');
    }
  }

  final orderedModules = state.allModulePaths.keys.toList()
    ..sort((a, b) {
      final levelA = state.moduleBuildLevel[a] ?? 999;
      final levelB = state.moduleBuildLevel[b] ?? 999;
      if (levelA != levelB) return levelA.compareTo(levelB);
      return a.compareTo(b);
    });

  for (final moduleName in orderedModules) {
    writeNode(moduleName);
  }

  content
    ..writeln('')
    ..writeln('    %% Edge colours follow the target module category')
    ..writeln(
      '    linkStyle default stroke:#b0bec5,stroke-width:1,opacity:0.35',
    );

  final edges = <String>[];
  final edgeStyles = <int, String>{};
  var edgeIndex = 0;

  final dependencyOrder = state.allModuleDependencies.keys.toList()..sort();
  for (final moduleName in dependencyOrder) {
    final deps = state.allModuleDependencies[moduleName];
    if (deps == null || deps.isEmpty) {
      continue;
    }

    final sortedDeps = deps.toList()..sort();

    for (final dep in sortedDeps) {
      final colour = moduleEdgeColor(dep);
      edges.add('    $dep --> $moduleName');
      edgeStyles[edgeIndex] = colour;
      edgeIndex++;
    }
  }

  for (final edge in edges) {
    content.writeln(edge);
  }

  if (edgeStyles.isNotEmpty) {
    content.writeln('');
    final indices = edgeStyles.keys.toList()..sort();
    for (final index in indices) {
      final colour = edgeStyles[index]!;
      content.writeln(
        '    linkStyle $index stroke:$colour,stroke-width:1.9,opacity:0.9',
      );
    }
  }

  content
    ..writeln('')
    ..writeln(
      '    classDef presentation fill:#e1f5fe,stroke:#0277bd,stroke-width:2px,color:#000000',
    )
    ..writeln(
      '    classDef domain fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000000',
    )
    ..writeln(
      '    classDef data fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px,color:#000000',
    )
    ..writeln(
      '    classDef ui fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000000',
    )
    ..writeln(
      '    classDef common fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000000',
    )
    ..writeln(
      '    classDef core fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000000',
    )
    ..writeln(
      '    classDef unused fill:#ffebee,stroke:#c62828,stroke-width:2px,color:#000000',
    )
    ..writeln('```')
    ..writeln('')
    ..writeln('## Build Statistics')
    ..writeln('');

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

  content
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
    ..writeln('')
    ..writeln('## Build Waves')
    ..writeln('')
    ..writeln(
      'The modules requiring build_runner will be built in the following waves:',
    )
    ..writeln('');

  var maxLevel = -1;
  for (final level in state.moduleBuildLevel.values) {
    if (level > maxLevel) {
      maxLevel = level;
    }
  }

  if (maxLevel < 0) {
    content.writeln('No modules require build_runner at this time.');
  } else {
    for (var level = 0; level <= maxLevel; level++) {
      content
        ..writeln('')
        ..writeln('### Wave $level')
        ..writeln('');

      for (final entry in state.moduleBuildLevel.entries) {
        if (entry.value == level) {
          final deps = state.moduleDependencies[entry.key] ?? <String>{};
          if (deps.isNotEmpty) {
            content.writeln(
              '- **${entry.key}** → depends on: ${deps.join(', ')}',
            );
          } else {
            content.writeln('- **${entry.key}** → no dependencies');
          }
        }
      }
    }
  }

  if (state.moduleUnusedDependencies.isNotEmpty) {
    content
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
      content.writeln('- **${entry.key}** → ${unused.join(', ')}');
    }
  }

  await File('build_graph.md').writeAsString(content.toString());
  Logger.success('Dependency graph saved to build_graph.md');
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
