import 'dart:io';

import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/core/state/build_state.dart';
import 'package:scripts/src/services/yaml_service.dart';

Future<Set<String>> parseDependencies(
  String pubspecPath,
  String moduleName,
  Map<String, String> knownModules,
) async {
  final dependencies = <String>{};

  try {
    final pubspec = await readPubspec(pubspecPath);
    if (pubspec == null) return dependencies;

    final deps = pubspec['dependencies'] as Map<String, dynamic>?;
    final devDeps = pubspec['dev_dependencies'] as Map<String, dynamic>?;

    void processDeps(Map<String, dynamic>? depsMap) {
      if (depsMap == null) return;

      depsMap.forEach((key, value) {
        final depName = key;

        if (!knownModules.containsKey(depName)) {
          return;
        }

        if (shouldIgnoreModule(depName)) {
          return;
        }

        dependencies.add(depName);
        Logger.debug('   Found dependency: $moduleName → $depName');
      });
    }

    processDeps(deps);
    processDeps(devDeps);
  } on Exception catch (e) {
    Logger.error('Error parsing dependencies from $pubspecPath: $e');
  }

  return dependencies;
}

Future<void> buildDependencyGraph(BuildState state) async {
  Logger.info('🕸️  Building dependency graph...');

  state.moduleDependencies.clear();
  state.allModuleDependencies.clear();
  state.moduleUnusedDependencies.clear();

  if (state.allModulePaths.isEmpty) {
    Logger.warning('No modules discovered for dependency analysis');
    return;
  }

  for (final entry in state.allModulePaths.entries) {
    final moduleName = entry.key;
    final modulePath = entry.value;
    final pubspecFile = '$modulePath/pubspec.yaml';

    final fullDependencies = await parseDependencies(
      pubspecFile,
      moduleName,
      state.allModulePaths,
    );
    state.allModuleDependencies[moduleName] = fullDependencies;

    if (state.modulePaths.containsKey(moduleName)) {
      final buildDependencies = fullDependencies
          .where(state.modulePaths.containsKey)
          .toSet();
      state.moduleDependencies[moduleName] = buildDependencies;

      if (buildDependencies.isNotEmpty) {
        Logger.info(
          '   📦 $moduleName depends on: ${buildDependencies.join(', ')}',
        );
      } else {
        Logger.verbose(
          '   📦 $moduleName has no internal build_runner dependencies',
        );
      }

      if (state.verbose) {
        final additionalDeps = fullDependencies.difference(buildDependencies);
        if (additionalDeps.isNotEmpty) {
          Logger.verbose(
            '   ↳ Additional non-build_runner deps: ${additionalDeps.join(', ')}',
          );
        }
      }
    } else if (state.verbose) {
      if (fullDependencies.isNotEmpty) {
        Logger.verbose(
          '   🧩 $moduleName (graph) depends on: ${fullDependencies.join(', ')}',
        );
      } else {
        Logger.verbose(
          '   🧩 $moduleName (graph) has no internal dependencies',
        );
      }
    }
  }

  if (state.verbose) {
    Logger.info('📊 Dependency Summary:');
    for (final entry in state.moduleDependencies.entries) {
      Logger.verbose(
        '${entry.key}: ${entry.value.length} build_runner dependencies',
      );
    }
  }
}

Future<Set<String>> _collectImportedPackages(
  BuildState state,
  String moduleName,
) async {
  final modulePath = state.allModulePaths[moduleName];
  if (modulePath == null) {
    return <String>{};
  }

  final importRegex = RegExp(
    "(?:import|export)\\s+['\"]package:([^/'\"]+)",
    multiLine: true,
  );
  final collected = <String>{};
  final directories = <String>['lib', 'src', 'bin', 'test', 'tool'];

  for (final dirName in directories) {
    final dir = Directory('$modulePath/$dirName');
    if (!dir.existsSync()) {
      continue;
    }

    try {
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }

        try {
          final content = await entity.readAsString();
          for (final match in importRegex.allMatches(content)) {
            final packageName = match.group(1);
            if (packageName != null && packageName.isNotEmpty) {
              collected.add(packageName);
            }
          }
        } on Exception catch (e) {
          Logger.debug('Error reading ${entity.path}: $e');
        }
      }
    } on Exception catch (e) {
      Logger.debug('Error scanning $modulePath/$dirName: $e');
    }
  }

  return collected;
}

Future<void> analyzeUnusedModuleDependencies(BuildState state) async {
  Logger.info('🧹 Analyzing unused module dependencies...');

  state.moduleUnusedDependencies.clear();

  for (final entry in state.allModuleDependencies.entries) {
    final moduleName = entry.key;
    final declaredDeps = entry.value;

    if (declaredDeps.isEmpty) {
      continue;
    }

    final importedPackages = await _collectImportedPackages(state, moduleName);
    final unused = declaredDeps.difference(importedPackages);

    if (unused.isNotEmpty) {
      state.moduleUnusedDependencies[moduleName] = unused;
      Logger.info('   🚫 $moduleName unused: ${unused.join(', ')}');
    } else if (state.verbose) {
      Logger.verbose('   ✅ $moduleName uses all declared modules');
    }
  }

  if (state.moduleUnusedDependencies.isEmpty) {
    Logger.success('No unused module dependencies detected.');
  }
}
