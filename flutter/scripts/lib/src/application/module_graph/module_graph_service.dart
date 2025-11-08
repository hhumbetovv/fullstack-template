import 'package:scripts/src/application/module_graph/workflows/build_plan_builder.dart';
import 'package:scripts/src/application/module_graph/workflows/dependency_analyzer.dart';
import 'package:scripts/src/application/module_graph/workflows/graph_generator.dart';
import 'package:scripts/src/application/workspace/workspace_state_loader.dart';
import 'package:scripts/src/core/state/build_state.dart';
import 'package:scripts/src/domain/models/build_plan.dart';
import 'package:scripts/src/domain/models/dependency_report.dart';
import 'package:scripts/src/domain/models/graph_report.dart';
import 'package:scripts/src/domain/ports/module_graph_port.dart';

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
  Future<DependencyReport> analyzeDependencies(BuildState state) async {
    await _dependencyAnalyzer.buildDependencyGraph(state);
    await _dependencyAnalyzer.analyzeUnusedModuleDependencies(state);
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
  Future<GraphReport> generateGraphFiles(BuildState state) async {
    return _graphGenerator.generate(state);
  }
}
