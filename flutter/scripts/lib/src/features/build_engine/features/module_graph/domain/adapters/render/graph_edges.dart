import 'package:scripts/src/features/build_engine/domain/models/build_state.dart';
import 'package:scripts/src/features/build_engine/domain/models/graph_config.dart';

Map<String, List<int>> writeGraphEdges(
  StringBuffer buffer,
  BuildState state,
  List<String> orderedModules,
  Set<String> includedNodes,
) {
  final edgeColorMap = <String, List<int>>{};
  var edgeIndex = 0;

  final dependencyOrder = orderedModules.toList()..sort();
  for (final moduleName in dependencyOrder) {
    final deps = state.allModuleDependencies[moduleName];
    if (deps == null || deps.isEmpty) {
      continue;
    }

    final filteredDeps = deps.where(includedNodes.contains).toList()..sort();

    for (final dep in filteredDeps) {
      final colour = moduleEdgeColor(dep);
      buffer.writeln('    $dep --> $moduleName');
      edgeColorMap.putIfAbsent(colour, () => <int>[]).add(edgeIndex);
      edgeIndex++;
    }
  }

  return edgeColorMap;
}
