part of 'package:scripts/src/services/workspace_discovery_service.dart';

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
    final usesBuildRunner = hasBuildRunner(modulePubspec);

    _registerModule(
      actualModuleName,
      cleanPath,
      usesBuildRunner,
      wasKnownModule,
    );
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
