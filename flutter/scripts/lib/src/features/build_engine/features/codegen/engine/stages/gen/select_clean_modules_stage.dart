import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/pipelines/gen/gen_context.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/gen/module_selector.dart';

class SelectCleanModulesStage implements Stage<GenCleanContext> {
  SelectCleanModulesStage(this._selector);

  final ModuleSelector _selector;

  @override
  String get name => 'select-clean-modules';

  @override
  Future<GenCleanContext> run(GenCleanContext context) async {
    final modules = await _selector.selectForClean();
    context.modules = modules;
    return context;
  }
}
