import 'dart:collection';

import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/core/state/build_state.dart';
import 'package:scripts/src/domain/models/build_plan.dart';

class BuildPlanBuilder {
  const BuildPlanBuilder();

  BuildPlan build(BuildState state) {
    state.moduleBuildLevel.clear();
    state.buildOrder.clear();

    final waves = <BuildWave>[];
    final order = <String>[];

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
        if (entry.value == 0 &&
            !state.moduleBuildLevel.containsKey(entry.key)) {
          state.moduleBuildLevel[entry.key] = level;
          waveModules.add(entry.key);
          processed++;
        }
      }

      if (waveModules.isEmpty && processed < total) {
        Logger.error('Circular dependency detected or disconnected modules!');
        throw Exception('Circular dependency detected');
      }

      if (waveModules.isNotEmpty) {
        waves.add(BuildWave(level: level, modules: waveModules));
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

    final inDegreeTopo = Map<String, int>.from(inDegree);
    final adjList = <String, Set<String>>{};

    for (final moduleName in state.modulePaths.keys) {
      adjList[moduleName] = <String>{};
    }

    for (final entry in state.moduleDependencies.entries) {
      final moduleName = entry.key;
      final dependencies = entry.value;

      for (final dep in dependencies) {
        if (state.modulePaths.containsKey(dep)) {
          adjList[dep]!.add(moduleName);
          inDegreeTopo[moduleName] = (inDegreeTopo[moduleName] ?? 0) + 1;
        }
      }
    }

    final queueTopo = Queue<String>();
    for (final entry in inDegreeTopo.entries) {
      if (entry.value == 0) {
        queueTopo.add(entry.key);
      }
    }

    while (queueTopo.isNotEmpty) {
      final current = queueTopo.removeFirst();
      order.add(current);

      for (final dependent in adjList[current]!) {
        final newDegree = (inDegreeTopo[dependent] ?? 0) - 1;
        inDegreeTopo[dependent] = newDegree;
        if (newDegree == 0) {
          queueTopo.add(dependent);
        }
      }
    }

    state.buildOrder = List<String>.from(order);

    return BuildPlan(waves: waves, order: order);
  }
}
