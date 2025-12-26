import 'package:scripts/src/features/build_engine/domain/models/build_plan.dart';
import 'package:scripts/src/features/build_engine/domain/models/build_state.dart';
import 'package:scripts/src/features/build_engine/domain/models/dependency_report.dart';
import 'package:scripts/src/features/build_engine/domain/models/graph_report.dart';

abstract class ModuleGraphPort {
  Future<void> discoverModules(BuildState state);

  Future<DependencyReport> analyzeDependencies(
    BuildState state, {
    bool quiet = false,
  });

  BuildPlan buildPlan(BuildState state);

  Future<GraphReport> generateGraphFiles(
    BuildState state, {
    bool quiet = false,
  });
}
