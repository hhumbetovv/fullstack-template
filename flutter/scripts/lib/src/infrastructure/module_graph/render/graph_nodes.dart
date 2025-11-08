import 'package:scripts/src/core/state/build_state.dart';
import 'package:scripts/src/domain/models/graph_config.dart';

class NodeWriteResult {
  const NodeWriteResult({
    required this.presentClasses,
    required this.focusUsed,
  });

  final Set<String> presentClasses;
  final bool focusUsed;
}

NodeWriteResult writeGraphNodes(
  StringBuffer buffer,
  BuildState state,
  GraphConfig config,
  Iterable<String> orderedModules,
  Set<String> modulesWithUnusedDeps,
) {
  final presentClasses = <String>{};
  var focusUsed = false;

  for (final moduleName in orderedModules) {
    final level = state.moduleBuildLevel[moduleName];
    final waveLabel = level != null ? '🌊 Wave $level' : '🚫 No build';
    buffer.writeln('    $moduleName["$moduleName\\n$waveLabel"]');

    final category = classifyModule(moduleName);
    if (category != null) {
      buffer.writeln('    $moduleName:::$category');
      presentClasses.add(category);
    }

    if (modulesWithUnusedDeps.contains(moduleName)) {
      buffer.writeln('    class $moduleName unused;');
      presentClasses.add('unused');
    }

    if (config.highlightPrimary && config.primaryModules.contains(moduleName)) {
      buffer.writeln('    class $moduleName focus;');
      focusUsed = true;
    }
  }

  return NodeWriteResult(
    presentClasses: presentClasses,
    focusUsed: focusUsed,
  );
}
