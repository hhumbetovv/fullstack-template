import 'package:common_tooling/tooling.dart';
import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/core/state/build_state.dart';
import 'package:scripts/src/services/yaml_service.dart';

/// Populates [BuildState] by reading workspace configuration from the root
/// pubspec and traversing workspace/path dependencies. Centralizing the logic
/// here prevents each executor from reimplementing module discovery.
class WorkspaceStateLoader {
  const WorkspaceStateLoader();

  Future<void> load(BuildState state) async {
    Logger.info('🔍 Discovering workspace modules...');

    state.resetWorkspace();

    final rootPubspec = await readPubspec('pubspec.yaml');
    if (rootPubspec == null) {
      throw const SmartBuildException('Could not read root pubspec.yaml');
    }

    final workspace = rootPubspec['workspace'];

    if (workspace is List) {
      Logger.info('Found workspace configuration, analyzing listed modules...');
      await _discoverWorkspaceModules(state, workspace.whereType<String>());
      return;
    }

    Logger.info('No workspace block found, scanning path dependencies...');
    await _discoverPathDependencies(state, rootPubspec);
  }

  Future<void> _discoverWorkspaceModules(
    BuildState state,
    Iterable<String> workspacePaths,
  ) async {
    final paths = workspacePaths.toList();
    if (paths.isEmpty) {
      Logger.warning('Workspace configuration found but no paths specified');
      return;
    }

    Logger.info('Found ${paths.length} workspace paths to analyze');

    for (final workspacePath in paths) {
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
          '   ⏭️  Skipped (generator module): '
          '$actualModuleName → $workspacePath',
        );
        continue;
      }

      final wasKnownModule = state.allModulePaths.containsKey(actualModuleName);
      final usesBuildRunner = hasBuildRunner(modulePubspec);

      _registerModule(
        state: state,
        moduleName: actualModuleName,
        cleanPath: cleanPath,
        usesBuildRunner: usesBuildRunner,
        wasKnownModule: wasKnownModule,
      );
    }

    Logger.success(
      'Analyzed ${paths.length} workspace paths → '
      '${state.modulePaths.length} build_runner modules, '
      '${state.allModulePaths.length} total modules for visualization',
    );

    if (state.verbose) {
      _logDiscoveredModules(state);
    }
  }

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

    final allDeps = <String, dynamic>{}
      ..addAll(dependencies ?? const {})
      ..addAll(devDependencies ?? const {});

    Logger.info('Found ${allDeps.length} dependencies to analyze');

    for (final entry in allDeps.entries) {
      final depName = entry.key;
      final depConfig = entry.value;
      Logger.debug('Analyzing dependency: $depName');

      if (depConfig is! Map<String, dynamic> ||
          !depConfig.containsKey('path')) {
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
          '   ⏭️  Skipped (generator module): '
          '$actualModuleName → $depPath',
        );
        continue;
      }

      final wasKnownModule = state.allModulePaths.containsKey(actualModuleName);
      final usesBuildRunner = hasBuildRunner(modulePubspec);

      _registerModule(
        state: state,
        moduleName: actualModuleName,
        cleanPath: cleanPath,
        usesBuildRunner: usesBuildRunner,
        wasKnownModule: wasKnownModule,
      );
    }

    Logger.success(
      'Analyzed ${allDeps.length} path dependencies → '
      '${state.modulePaths.length} build_runner modules, '
      '${state.allModulePaths.length} total modules for visualization',
    );

    if (state.verbose) {
      _logDiscoveredModules(state);
    }
  }

  void _registerModule({
    required BuildState state,
    required String moduleName,
    required String cleanPath,
    required bool usesBuildRunner,
    required bool wasKnownModule,
  }) {
    state.allModulePaths[moduleName] = cleanPath;

    if (!usesBuildRunner) {
      if (state.verbose && !wasKnownModule) {
        Logger.verbose(
          'ℹ️  Module (no build_runner): $moduleName → $cleanPath',
        );
      }
      return;
    }

    state.modulePaths[moduleName] = cleanPath;
    state.moduleBuildStatus[moduleName] = BuildStatus.pending;
    Logger.verbose('✅ Module found: $moduleName → $cleanPath');
  }

  void _logDiscoveredModules(BuildState state) {
    Logger.info('📋 All discovered modules:');
    for (final entry in state.modulePaths.entries) {
      Logger.verbose('${entry.key} → ${entry.value}');
    }
  }
}
