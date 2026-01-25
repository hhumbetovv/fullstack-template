import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/build_engine/features/codegen/commands/smart_build/smart_build_context.dart';

class RetainTargetModuleStage
    implements Stage<SmartBuildContext> {
  const RetainTargetModuleStage();

  @override
  String get name => 'retain-target-module';

  @override
  SmartBuildContext run(SmartBuildContext context) {
    final target = context.options.targetModule;
    if (target == null) {
      return context;
    }

    final state = context.state;
    if (!state.modulePaths.containsKey(target)) {
      throw CommandError(
        'Module $target not found among workspace packages.',
        exitCode: 64,
      );
    }

    final requiredModules = <String>{target};
    var changed = true;
    while (changed) {
      changed = false;
      for (final moduleName in requiredModules.toList()) {
        final dependencies = state.moduleDependencies[moduleName] ?? <String>{};
        for (final dep in dependencies) {
          if (requiredModules.add(dep)) {
            changed = true;
            Logger.debug('Added required dependency: $dep');
          }
        }
      }
    }

    final modulesToRemove = <String>[];
    for (final moduleName in state.modulePaths.keys) {
      if (!requiredModules.contains(moduleName)) {
        modulesToRemove.add(moduleName);
      }
    }

    for (final moduleName in modulesToRemove) {
      state.modulePaths.remove(moduleName);
      state.moduleDependencies.remove(moduleName);
      state.moduleBuildStatus.remove(moduleName);
      state.allModulePaths.remove(moduleName);
      state.allModuleDependencies.remove(moduleName);
      state.moduleUnusedDependencies.remove(moduleName);
    }

    for (final deps in state.moduleDependencies.values) {
      deps.removeWhere(modulesToRemove.contains);
    }
    for (final deps in state.allModuleDependencies.values) {
      deps.removeWhere(modulesToRemove.contains);
    }
    for (final deps in state.moduleUnusedDependencies.values) {
      deps.removeWhere(modulesToRemove.contains);
    }

    state.invalidateWorkspaceSnapshot();
    return context;
  }
}
