import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/build_engine/domain/models/build_state.dart';
import 'package:scripts/src/features/build_engine/features/codegen/commands/smart_build/smart_build_context.dart';
import 'package:scripts/src/features/build_engine/features/codegen/domain/models/smart_build_options.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/smart_build/build_log_reader.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/smart_build/error_module_analyzer.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/smart_build/git_change_detector.dart';

class FilterModulesStage implements Stage<SmartBuildContext> {
  const FilterModulesStage({
    required BuildLogMetadataReader logReader,
    required GitChangeDetector gitChangeDetector,
    required ErrorModuleAnalyzer errorModuleAnalyzer,
  }) : _logReader = logReader,
       _gitChangeDetector = gitChangeDetector,
       _errorModuleAnalyzer = errorModuleAnalyzer;

  final BuildLogMetadataReader _logReader;
  final GitChangeDetector _gitChangeDetector;
  final ErrorModuleAnalyzer _errorModuleAnalyzer;

  @override
  String get name => 'filter-modules';

  @override
  Future<SmartBuildContext> run(SmartBuildContext context) async {
    final state = context.state;
    final mode = context.options.mode;

    if (mode == SmartBuildMode.all) {
      return context;
    }
    if (state.targetModule != null) {
      if (state.verbose) {
        Logger.verbose(
          'Target module detected (${state.targetModule}), '
          'skipping $mode filtering.',
        );
      }
      return context;
    }

    context.graphState ??= state.clone();

    final logMetadata = await _logReader.read(state.buildLogsDir);
    var selected = await _selectModules(state, mode, logMetadata);
    selected = selected.where(state.modulePaths.containsKey).toSet();

    if (selected.isEmpty) {
      context
        ..skipBuild = true
        ..skipReason =
            'No modules matched `${mode.description}` mode. Nothing to build.';
      _clearWorkspace(state);
      return context;
    }

    final selectedCount = selected.length;
    final totalModules = state.modulePaths.length;
    _retainModules(state, selected);

    Logger.info(
      '🎯 smart-build mode `${mode.description}` scheduled '
      '$selectedCount of $totalModules modules.',
    );
    if (state.verbose) {
      final sorted = selected.toList()..sort();
      Logger.verbose('Selected modules: ${sorted.join(', ')}');
    }

    return context;
  }

  Future<Set<String>> _selectModules(
    BuildState state,
    SmartBuildMode mode,
    Map<String, BuildLogEntry> logMetadata,
  ) {
    switch (mode) {
      case SmartBuildMode.gitChange:
        return _gitChangeDetector.findModulesWithChanges(
          modulePaths: state.modulePaths,
          logMetadata: logMetadata,
        );
      case SmartBuildMode.error:
        return _errorModuleAnalyzer.findProblematicModules(
          modulePaths: state.modulePaths,
          logMetadata: logMetadata,
        );
      case SmartBuildMode.all:
        return Future.value(state.modulePaths.keys.toSet());
    }
  }

  void _retainModules(BuildState state, Set<String> keep) {
    final modulesToRemove = <String>[];
    for (final moduleName in List<String>.from(state.modulePaths.keys)) {
      if (!keep.contains(moduleName)) {
        modulesToRemove.add(moduleName);
      }
    }

    for (final module in modulesToRemove) {
      state.modulePaths.remove(module);
      state.moduleDependencies.remove(module);
      state.moduleBuildStatus.remove(module);
      state.modulePackageDependencies.remove(module);
      state.moduleUnusedPackages.remove(module);
    }

    for (final deps in state.moduleDependencies.values) {
      deps.removeWhere(modulesToRemove.contains);
    }

    state.invalidateWorkspaceSnapshot();
  }

  void _clearWorkspace(BuildState state) {
    state.modulePaths.clear();
    state.moduleDependencies.clear();
    state.moduleBuildStatus.clear();
    state.allModulePaths.clear();
    state.allModuleDependencies.clear();
    state.moduleUnusedDependencies.clear();
    state.modulePackageDependencies.clear();
    state.moduleUnusedPackages.clear();
    state.invalidateWorkspaceSnapshot();
  }
}
