import 'package:scripts/src/features/build_engine/domain/models/build_plan.dart';
import 'package:scripts/src/features/build_engine/domain/models/build_state.dart';
import 'package:scripts/src/features/build_engine/domain/models/dependency_report.dart';
import 'package:scripts/src/features/build_engine/domain/models/graph_report.dart';
import 'package:scripts/src/features/build_engine/domain/ports/module_graph_port.dart';
import 'package:scripts/src/features/build_engine/engine/services/workspace_state_loader.dart';
import 'package:scripts/src/features/build_engine/features/module_graph/engine/services/build_plan_builder.dart';
import 'package:scripts/src/features/build_engine/features/module_graph/engine/services/dependency_analyzer.dart';
import 'package:scripts/src/features/build_engine/features/module_graph/engine/services/graph_generator.dart';

class ModuleGraphService implements ModuleGraphPort {
  ModuleGraphService({
    required DependencyAnalyzer dependencyAnalyzer,
    required BuildPlanBuilder buildPlanBuilder,
    required GraphGenerator graphGenerator,
    required WorkspaceStateLoader workspaceStateLoader,
  }) : _dependencyAnalyzer = dependencyAnalyzer,
       _buildPlanBuilder = buildPlanBuilder,
       _graphGenerator = graphGenerator,
       _workspaceStateLoader = workspaceStateLoader;

  final DependencyAnalyzer _dependencyAnalyzer;
  final BuildPlanBuilder _buildPlanBuilder;
  final GraphGenerator _graphGenerator;
  final WorkspaceStateLoader _workspaceStateLoader;

  @override
  Future<void> discoverModules(BuildState state) async {
    await _workspaceStateLoader.load(state);
  }

  @override
  Future<DependencyReport> analyzeDependencies(
    BuildState state, {
    bool quiet = false,
  }) async {
    await _dependencyAnalyzer.buildDependencyGraph(
      state,
      quiet: quiet,
    );
    await _dependencyAnalyzer.analyzeUnusedModuleDependencies(
      state,
      quiet: quiet,
    );
    return DependencyReport(
      moduleDependencies: state.moduleDependencies,
      allDependencies: state.allModuleDependencies,
      unusedDependencies: state.moduleUnusedDependencies,
    );
  }

  @override
  BuildPlan buildPlan(BuildState state) {
    return _buildPlanBuilder.build(state);
  }

  @override
  Future<GraphReport> generateGraphFiles(
    BuildState state, {
    bool quiet = false,
  }) async {
    return _graphGenerator.generate(state, quiet: quiet);
  }
}
