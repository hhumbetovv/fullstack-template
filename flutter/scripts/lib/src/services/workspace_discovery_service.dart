import 'package:common_tooling/tooling.dart';

import '../core/core.dart';
import 'yaml_service.dart';

Future<void> _discoverWorkspaceModules(List<dynamic> workspace) async {
  final workspacePaths = workspace.whereType<String>();

  if (workspacePaths.isEmpty) {
    Logger.warning('Workspace configuration found but no paths specified');
    return;
  }

  final totalPaths = workspacePaths.length;
  Logger.info('Found $totalPaths workspace paths to analyze');

  for (final workspacePath in workspacePaths) {
    Logger.debug('Analyzing workspace path: $workspacePath');

    final cleanPath = ensureDotRelative(workspacePath);

    final pubspecPath = '$cleanPath/pubspec.yaml';
    Logger.debug('   Checking: $pubspecPath');

    final modulePubspec = await readPubspec(pubspecPath);
    if (modulePubspec == null) {
      Logger.debug('   ⏭️  Skipped (no pubspec.yaml): $workspacePath');
      continue;
    }

    final actualModuleName = getPackageName(modulePubspec);
    if (actualModuleName == null) {
      Logger.debug('   ⏭️  Skipped (no name in pubspec): $workspacePath');
      continue;
    }

    if (shouldIgnoreModule(actualModuleName)) {
      Logger.debug(
        '   ⏭️  Skipped (generator module): $actualModuleName → $workspacePath',
      );
      continue;
    }

    final wasKnownModule = state.allModulePaths.containsKey(actualModuleName);
    state.allModulePaths[actualModuleName] = cleanPath;

    final usesBuildRunner = hasBuildRunner(modulePubspec);

    if (!usesBuildRunner) {
      if (state.verbose && !wasKnownModule) {
        Logger.verbose(
          'ℹ️  Module (no build_runner): $actualModuleName → $cleanPath',
        );
      }
      continue;
    }

    state.modulePaths[actualModuleName] = cleanPath;
    state.moduleBuildStatus[actualModuleName] = BuildStatus.pending;

    Logger.verbose('✅ Module found: $actualModuleName → $cleanPath');
  }

  Logger.success(
    'Analyzed $totalPaths workspace paths → ${state.modulePaths.length} build_runner modules, '
    '${state.allModulePaths.length} total modules for visualization',
  );

  if (state.verbose) {
    Logger.info('📋 All discovered modules:');
    for (final entry in state.modulePaths.entries) {
      Logger.verbose('${entry.key} → ${entry.value}');
    }
  }
}

Future<void> _discoverPathDependencies(Map<String, dynamic> rootPubspec) async {
  final dependencies = rootPubspec['dependencies'] as Map<String, dynamic>?;
  final devDependencies =
      rootPubspec['dev_dependencies'] as Map<String, dynamic>?;

  if (dependencies == null && devDependencies == null) {
    Logger.warning('No dependencies found in root pubspec.yaml');
    return;
  }

  final allDeps = <String, dynamic>{};
  if (dependencies != null) {
    dependencies.forEach((key, value) {
      allDeps[key] = value;
    });
  }
  if (devDependencies != null) {
    devDependencies.forEach((key, value) {
      allDeps[key] = value;
    });
  }

  final totalDeps = allDeps.length;
  Logger.info('Found $totalDeps dependencies to analyze');

  for (final entry in allDeps.entries) {
    final depName = entry.key;
    final depConfig = entry.value;

    Logger.debug('Analyzing dependency: $depName');

    if (depConfig is! Map<String, dynamic> || !depConfig.containsKey('path')) {
      Logger.debug('   ⏭️  Skipped (not a path dependency): $depName');
      continue;
    }

    final depPath = depConfig['path']?.toString();
    if (depPath == null) {
      Logger.debug('   ⏭️  Skipped (no path): $depName');
      continue;
    }

    final cleanPath = ensureDotRelative(depPath);

    final pubspecPath = '$cleanPath/pubspec.yaml';
    Logger.debug('   Checking: $pubspecPath');

    final modulePubspec = await readPubspec(pubspecPath);
    if (modulePubspec == null) {
      Logger.debug('   ⏭️  Skipped (no pubspec.yaml): $depPath');
      continue;
    }

    final actualModuleName = getPackageName(modulePubspec);
    if (actualModuleName == null) {
      Logger.debug('   ⏭️  Skipped (no name in pubspec): $depPath');
      continue;
    }

    if (shouldIgnoreModule(actualModuleName)) {
      Logger.debug(
        '   ⏭️  Skipped (generator module): $actualModuleName → $depPath',
      );
      continue;
    }

    final wasKnownModule = state.allModulePaths.containsKey(actualModuleName);
    state.allModulePaths[actualModuleName] = cleanPath;

    final usesBuildRunner = hasBuildRunner(modulePubspec);

    if (!usesBuildRunner) {
      if (state.verbose && !wasKnownModule) {
        Logger.verbose(
          'ℹ️  Module (no build_runner): $actualModuleName → $cleanPath',
        );
      }
      continue;
    }

    state.modulePaths[actualModuleName] = cleanPath;
    state.moduleBuildStatus[actualModuleName] = BuildStatus.pending;

    Logger.verbose('✅ Module found: $actualModuleName → $cleanPath');
  }

  Logger.success(
    'Analyzed $totalDeps path dependencies → ${state.modulePaths.length} build_runner modules, '
    '${state.allModulePaths.length} total modules for visualization',
  );

  if (state.verbose) {
    Logger.info('📋 All discovered modules:');
    for (final entry in state.modulePaths.entries) {
      Logger.verbose('${entry.key} → ${entry.value}');
    }
  }
}

Future<void> discoverModulesFromRoot() async {
  Logger.info('🔍 Discovering modules from root pubspec.yaml...');

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

  final rootPubspec = await readPubspec('pubspec.yaml');

  if (rootPubspec == null) {
    throw SmartBuildException('Could not read root pubspec.yaml');
  }

  final workspace = rootPubspec['workspace'];

  if (workspace != null && workspace is List) {
    Logger.info(
      'Found workspace configuration, analyzing workspace modules...',
    );
    await _discoverWorkspaceModules(workspace);
    return;
  }

  Logger.info('No workspace found, checking path dependencies...');
  await _discoverPathDependencies(rootPubspec);
}
