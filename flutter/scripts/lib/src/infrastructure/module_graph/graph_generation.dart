import 'dart:io';

import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/core/state/build_state.dart';
import 'package:scripts/src/infrastructure/module_graph/graph_config.dart';
import 'package:scripts/src/infrastructure/module_graph/render/graph_edges.dart';
import 'package:scripts/src/infrastructure/module_graph/render/graph_nodes.dart';
import 'package:scripts/src/infrastructure/module_graph/render/graph_styles.dart';

Future<bool> writeGraphFile(
  BuildState state,
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

  final nodeResult = writeGraphNodes(
    content,
    state,
    config,
    orderedModules,
    modulesWithUnusedDeps,
  );

  content
    ..writeln('')
    ..writeln('    %% Edge styling')
    ..writeln(
      '    linkStyle default stroke:#b0bec5,stroke-width:1,opacity:0.35',
    );

  final edgeColorMap = writeGraphEdges(
    content,
    state,
    orderedModules,
    nodes,
  );

  writeEdgeStyles(content, edgeColorMap);
  content.writeln('');

  writeClassStyles(
    content,
    nodeResult.presentClasses,
    nodeResult.focusUsed,
  );

  content
    ..writeln('```')
    ..writeln('');

  await File(config.path).writeAsString(content.toString());
  return true;
}

Future<void> generateMermaidGraph(BuildState state) async {
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

  const categoryLabels = <String, String>{
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

  final featureGroups = <String, bool Function(String)>{
    'auth': (name) => name.startsWith('auth_'),
    'session': (name) => name.startsWith('session_'),
    'campaign': (name) => name.startsWith('campaign_'),
    'qr_scan': (name) => name.startsWith('qr_scan_'),
    'main': (name) =>
        name.startsWith('main_') ||
        name.startsWith('home_') ||
        name.startsWith('profile_'),
    'global': (name) => name.contains('console') || name.contains('info'),
    'splash': (name) => name.startsWith('splash_'),
  };

  for (final entry in featureGroups.entries) {
    final key = entry.key;
    final matcher = entry.value;
    final modules = allModules.where(matcher).toSet();
    if (modules.isEmpty) {
      continue;
    }
    final prettyKey = key.replaceAll('_', ' ').toUpperCase();
    graphs.add(
      GraphConfig(
        path: 'build_info/graph_feature_$key.md',
        title: '$prettyKey Feature Graph',
        primaryModules: modules,
        section: 'features',
        description: '$prettyKey feature modules with their dependencies.',
      ),
    );
  }

  final generatedGraphs = <GraphConfig>[];
  for (final graph in graphs) {
    final wrote = await writeGraphFile(state, graph, modulesWithUnusedDeps);
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
      final items =
          generatedGraphs.where((graph) => graph.section == section).toList()
            ..sort((a, b) => a.title.compareTo(b.title));
      if (items.isEmpty) continue;

      summary
        ..writeln('### ${sectionTitles[section] ?? section}')
        ..writeln('');

      for (final graph in items) {
        final description =
            (graph.description != null && graph.description!.isNotEmpty)
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
          state.moduleBuildLevel.entries
              .where((entry) => entry.value == level)
              .map((entry) => entry.key)
              .toList()
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

    final sortedEntries = state.moduleUnusedDependencies.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in sortedEntries) {
      final unused = entry.value.toList()..sort();
      summary.writeln('- **${entry.key}** → ${unused.join(', ')}');
    }
  }

  summary
    ..writeln('')
    ..writeln(
      '_Detailed graphs are available under the `build_info/` directory._',
    )
    ..writeln('');

  await File('build_graph.md').writeAsString(summary.toString());
  Logger.success('Dependency graph summary saved to build_graph.md');
  Logger.info('Supplementary graph files generated in build_info/.');
}
