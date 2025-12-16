import 'dart:io';

import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/features/codegen/domain/models/build_state.dart';
import 'package:scripts/src/features/scaffolding/services/yaml_service.dart';

class DependencyAnalyzer {
  Future<void> buildDependencyGraph(BuildState state) async {
    Logger.info('🕸️  Building dependency graph...');

    state.moduleDependencies.clear();
    state.allModuleDependencies.clear();
    state.moduleUnusedDependencies.clear();
    state.modulePackageDependencies.clear();
    state.moduleUnusedPackages.clear();

    if (state.allModulePaths.isEmpty) {
      Logger.warning('No modules discovered for dependency analysis');
      return;
    }

    for (final entry in state.allModulePaths.entries) {
      final moduleName = entry.key;
      final modulePath = entry.value;
      final pubspecFile = '$modulePath/pubspec.yaml';

      final dependencySets = await _parseDependencies(
        pubspecFile,
        moduleName,
        state.allModulePaths,
      );
      final fullDependencies = dependencySets.moduleDependencies;
      state.allModuleDependencies[moduleName] = fullDependencies;
      state.modulePackageDependencies[moduleName] = dependencySets.packageDependencies;

      if (!state.modulePaths.containsKey(moduleName) && state.verbose) {
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

    _populateBuildDependencies(state);

    if (state.verbose) {
      Logger.info('📊 Dependency Summary:');
      for (final entry in state.moduleDependencies.entries) {
        Logger.verbose(
          '${entry.key}: ${entry.value.length} build_runner dependencies',
        );
      }
    }
  }

  Future<void> analyzeUnusedModuleDependencies(BuildState state) async {
    Logger.info('🧹 Analyzing unused module dependencies...');

    state.moduleUnusedDependencies.clear();
    state.moduleUnusedPackages.clear();

    for (final entry in state.allModuleDependencies.entries) {
      final moduleName = entry.key;
      final declaredDeps = entry.value;
      final filteredDeclaredDeps = declaredDeps.where((dep) => !shouldIgnoreModule(dep)).toSet();
      final declaredPackages = state.modulePackageDependencies[moduleName] ?? <String>{};

      if (filteredDeclaredDeps.isEmpty && declaredPackages.isEmpty) {
        continue;
      }

      final importedPackages = await _collectImportedPackages(
        state,
        moduleName,
      );
      final unused = filteredDeclaredDeps.difference(importedPackages);
      final unusedPackages = declaredPackages.difference(importedPackages);

      if (unused.isNotEmpty) {
        state.moduleUnusedDependencies[moduleName] = unused;
        Logger.info('   🚫 $moduleName unused modules: ${unused.join(', ')}');
      } else if (state.verbose) {
        Logger.verbose('   ✅ $moduleName uses all declared modules');
      }

      if (unusedPackages.isNotEmpty) {
        state.moduleUnusedPackages[moduleName] = unusedPackages;
        Logger.info(
          '   📦 $moduleName unused packages: ${unusedPackages.join(', ')}',
        );
      } else if (state.verbose && declaredPackages.isNotEmpty) {
        Logger.verbose('   📦 $moduleName uses all declared packages');
      }
    }

    if (state.moduleUnusedDependencies.isEmpty) {
      Logger.success('No unused module dependencies detected.');
    }
    if (state.moduleUnusedPackages.isEmpty) {
      Logger.success('No unused external packages detected.');
    }
  }

  Future<_DependencySets> _parseDependencies(
    String pubspecPath,
    String moduleName,
    Map<String, String> knownModules,
  ) async {
    final dependencies = <String>{};
    final packages = <String>{};

    try {
      final pubspec = await readPubspec(pubspecPath);
      if (pubspec == null) {
        return const _DependencySets();
      }

      final deps = pubspec['dependencies'] as Map<String, dynamic>?;
      final devDeps = pubspec['dev_dependencies'] as Map<String, dynamic>?;
      final overrideDeps = pubspec['dependency_overrides'] as Map<String, dynamic>?;

      void processDeps(Map<String, dynamic>? depsMap) {
        if (depsMap == null) return;

        depsMap.forEach((key, value) {
          final depName = key;

          if (knownModules.containsKey(depName)) {
            dependencies.add(depName);
            Logger.debug('   Found module dependency: $moduleName → $depName');
            return;
          }

          packages.add(depName);
          Logger.debug('   Found external dependency: $moduleName → $depName');
        });
      }

      processDeps(deps);
      processDeps(devDeps);
      processDeps(overrideDeps);
    } on Object catch (e) {
      Logger.error('Error parsing dependencies from $pubspecPath: $e');
    }

    return _DependencySets(
      moduleDependencies: dependencies,
      packageDependencies: packages,
    );
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
          } on Object catch (e) {
            Logger.debug('Error reading ${entity.path}: $e');
          }
        }
      } on Object catch (e) {
        Logger.debug('Error scanning $modulePath/$dirName: $e');
      }
    }

    return collected;
  }

  void _populateBuildDependencies(BuildState state) {
    for (final moduleName in state.modulePaths.keys) {
      final fullDependencies = state.allModuleDependencies[moduleName] ?? const <String>{};
      final buildDependencies = _flattenToBuildModules(
        state,
        moduleName,
        fullDependencies,
      );
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
        final additionalDeps = fullDependencies.where((dep) => !state.modulePaths.containsKey(dep)).toSet();
        if (additionalDeps.isNotEmpty) {
          Logger.verbose(
            '   ↳ Additional non-build_runner deps: '
            '${additionalDeps.join(', ')}',
          );
        }
      }
    }
  }

  Set<String> _flattenToBuildModules(
    BuildState state,
    String moduleName,
    Set<String> directDependencies,
  ) {
    final resolved = <String>{};
    final visited = <String>{moduleName};

    void visit(String dep) {
      if (!visited.add(dep)) {
        return;
      }

      if (state.modulePaths.containsKey(dep)) {
        resolved.add(dep);
        return;
      }

      final transitive = state.allModuleDependencies[dep];
      if (transitive == null || transitive.isEmpty) {
        return;
      }

      for (final nested in transitive) {
        visit(nested);
      }
    }

    for (final dep in directDependencies) {
      visit(dep);
    }

    return resolved;
  }
}

class _DependencySets {
  const _DependencySets({
    Set<String>? moduleDependencies,
    Set<String>? packageDependencies,
  }) : moduleDependencies = moduleDependencies ?? const <String>{},
       packageDependencies = packageDependencies ?? const <String>{};

  final Set<String> moduleDependencies;
  final Set<String> packageDependencies;
}
