part of 'package:scripts/src/services/workspace_discovery_service.dart';

Future<void> _discoverPathDependencies(
  BuildState state,
  Map<String, dynamic> rootPubspec,
) async {
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
    final usesBuildRunner = hasBuildRunner(modulePubspec);

    _registerModule(
      state,
      actualModuleName,
      cleanPath,
      usesBuildRunner,
      wasKnownModule,
    );
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
