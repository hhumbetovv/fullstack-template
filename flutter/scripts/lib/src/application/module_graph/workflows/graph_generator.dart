import 'dart:io';

import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/core/state/build_state.dart';
import 'package:scripts/src/domain/models/graph_report.dart';
import 'package:scripts/src/infrastructure/module_graph/graph_config.dart';
import 'package:scripts/src/infrastructure/module_graph/graph_generation.dart'
    as legacy_graph;

class GraphGenerator {
  const GraphGenerator();

  Future<GraphReport> generate(BuildState state) async {
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
          description:
              'Modules scheduled in wave $wave with their workspace dependencies.',
        ),
      );
    }

    final categoryLabels = <String, String>{
      'common': 'Common Layer',
      'core': 'Core Layer',
      'ui': 'UI Layer',
      'domain': 'Domain Layer',
      'data': 'Data Layer',
      'presentation': 'Presentation Layer',
    };

    for (final entry in categoryLabels.entries) {
      final category = entry.key;
      final label = entry.value;
      final modules = allModules
          .where((module) => classifyModule(module) == category)
          .toSet();
      if (modules.isEmpty) {
        continue;
      }
      graphs.add(
        GraphConfig(
          path: 'build_info/graph_layer_$category.md',
          title: '$label Graph',
          primaryModules: modules,
          section: 'layers',
          description: '$label modules with their workspace dependencies.',
        ),
      );
    }

    final generatedGraphs = <GraphConfig>[];
    for (final graph in graphs) {
      final wrote = await legacy_graph.writeGraphFile(
        state,
        graph,
        modulesWithUnusedDeps,
      );
      if (wrote) {
        generatedGraphs.add(graph);
      }
    }

    return GraphReport(
      summary: GraphSummary(
        totalModules: state.allModulePaths.length,
        totalDependencies: state.allModuleDependencies.values.fold<int>(
          0,
          (sum, deps) => sum + deps.length,
        ),
        modulesWithUnused: modulesWithUnusedDeps,
      ),
      outputs: [
        for (final graph in generatedGraphs)
          GraphFile(path: graph.path, title: graph.title),
      ],
    );
  }
}
