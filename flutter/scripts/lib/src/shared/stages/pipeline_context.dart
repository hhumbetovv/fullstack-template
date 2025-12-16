import 'package:scripts/src/features/codegen/domain/models/build_plan.dart';
import 'package:scripts/src/features/codegen/domain/models/build_state.dart';
import 'package:scripts/src/features/module_graph/domain/models/dependency_report.dart';
import 'package:scripts/src/features/module_graph/domain/models/graph_report.dart';

/// Common context used by graph/codegen pipelines.
class PipelineContext {
  PipelineContext({required this.state});

  final BuildState state;
  DependencyReport? dependencyReport;
  BuildPlan? buildPlan;
  GraphReport? graphReport;
}
