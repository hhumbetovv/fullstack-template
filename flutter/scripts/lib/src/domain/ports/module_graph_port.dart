import 'package:scripts/src/core/state/build_state.dart';
import 'package:scripts/src/domain/models/build_plan.dart';
import 'package:scripts/src/domain/models/dependency_report.dart';
import 'package:scripts/src/domain/models/graph_report.dart';

abstract class ModuleGraphPort {
  Future<void> discoverModules(BuildState state);

  Future<DependencyReport> analyzeDependencies(BuildState state);

  BuildPlan buildPlan(BuildState state);

  Future<GraphReport> generateGraphFiles(BuildState state);
}
