import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/pipelines/gen/gen_context.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/module_selector.dart';

class SelectWatchModulesStage implements Stage<GenWatchContext> {
  SelectWatchModulesStage(this._selector);

  final ModuleSelector _selector;

  @override
  String get name => 'select-watch-modules';

  @override
  Future<GenWatchContext> run(GenWatchContext context) async {
    final modules = await _selector.selectForWatch(context.filters);
    context
      ..modules = modules
      ..exitCode = modules.isEmpty ? 0 : context.exitCode;
    return context;
  }
}
