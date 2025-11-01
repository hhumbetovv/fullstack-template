import 'package:common_tooling/tooling.dart';
import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/core/state/build_state.dart';

import 'package:scripts/src/services/yaml_service.dart';

part 'workspace_discovery/module_registry.dart';
part 'workspace_discovery/path_dependency_scanner.dart';
part 'workspace_discovery/workspace_scanner.dart';

Future<void> discoverModulesFromRoot(BuildState state) async {
  Logger.info('🔍 Discovering modules from root pubspec.yaml...');

  _resetDiscoveryState(state);

  final rootPubspec = await readPubspec('pubspec.yaml');

  if (rootPubspec == null) {
    throw const SmartBuildException('Could not read root pubspec.yaml');
  }

  final workspace = rootPubspec['workspace'];

  if (workspace != null && workspace is List) {
    Logger.info(
      'Found workspace configuration, analyzing workspace modules...',
    );
    await _discoverWorkspaceModules(state, workspace);
    return;
  }

  Logger.info('No workspace found, checking path dependencies...');
  await _discoverPathDependencies(state, rootPubspec);
}

void _resetDiscoveryState(BuildState state) {
  state.modulePaths.clear();
  state.allModulePaths.clear();
  state.moduleDependencies.clear();
  state.allModuleDependencies.clear();
  state.moduleUnusedDependencies.clear();
  state.moduleBuildStatus.clear();
  state.modulePids.clear();
  state.moduleBuildLevel.clear();
  state.buildOrder.clear();
  state.currentlyBuilding.clear();
}
