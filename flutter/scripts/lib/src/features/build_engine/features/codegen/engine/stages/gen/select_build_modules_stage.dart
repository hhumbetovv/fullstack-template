import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/pipelines/gen/gen_context.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/module_selector.dart';

class SelectBuildModulesStage implements Stage<GenBuildContext> {
  SelectBuildModulesStage(this._selector);

  final ModuleSelector _selector;

  @override
  String get name => 'select-build-modules';

  @override
  Future<GenBuildContext> run(GenBuildContext context) async {
    final modules = await _selector.selectForBuild(context.filters);
    context
      ..modules = modules
      ..exitCode = modules.isEmpty ? (context.filters.isEmpty ? 1 : 0) : 0;
    return context;
  }
}
