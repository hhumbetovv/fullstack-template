import 'package:scripts/src/core/build_state.dart';
import 'package:scripts/src/core/errors.dart';
import 'package:scripts/src/core/logging.dart';

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

    throw const SmartBuildException('', exitCode: 1);
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
