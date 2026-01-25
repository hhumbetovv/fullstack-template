import 'package:scripts/src/features/build_engine/domain/models/build_plan.dart';
import 'package:scripts/src/features/build_engine/domain/models/build_state.dart';
import 'package:scripts/src/features/build_engine/domain/models/dependency_report.dart';
import 'package:scripts/src/features/build_engine/domain/models/graph_report.dart';

/// Common context used by graph/codegen pipelines.
class PipelineContext {
  PipelineContext({
    required this.state,
    this.quiet = false,
  });

  final BuildState state;
  final bool quiet;
  BuildState? graphState;
  DependencyReport? dependencyReport;
  BuildPlan? buildPlan;
  GraphReport? graphReport;
}
