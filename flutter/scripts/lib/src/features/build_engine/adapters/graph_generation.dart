import 'dart:io';

import 'package:scripts/src/features/build_engine/adapters/render/graph_edges.dart';
import 'package:scripts/src/features/build_engine/adapters/render/graph_nodes.dart';
import 'package:scripts/src/features/build_engine/adapters/render/graph_styles.dart';
import 'package:scripts/src/features/build_engine/domain/models/build_state.dart';
import 'package:scripts/src/features/build_engine/domain/models/graph_config.dart';

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
