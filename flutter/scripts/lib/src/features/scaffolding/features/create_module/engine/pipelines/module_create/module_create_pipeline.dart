import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/scaffolding/domain/adapters/module_config_service.dart';
import 'package:scripts/src/features/scaffolding/features/create_module/engine/pipelines/module_create/module_create_context.dart';
import 'package:scripts/src/features/scaffolding/features/create_module/engine/stages/module_create/bootstrap_pubspec_stage.dart';
import 'package:scripts/src/features/scaffolding/features/create_module/engine/stages/module_create/copy_template_stage.dart';
import 'package:scripts/src/features/scaffolding/features/create_module/engine/stages/module_create/register_workspace_stage.dart';
import 'package:scripts/src/features/scaffolding/features/create_module/engine/stages/module_create/resolve_template_stage.dart';
import 'package:scripts/src/features/scaffolding/features/create_module/engine/stages/module_create/validate_input_stage.dart';

class ModuleCreatePipeline {
  ModuleCreatePipeline({
    required ModuleConfigService moduleConfigService,
    required String workspaceRoot,
  })  : _validateInput = ValidateInputStage(workspaceRoot),
        _resolveTemplate = ResolveTemplateStage(workspaceRoot),
        _copyTemplate = CopyTemplateStage(workspaceRoot),
        _bootstrapPubspec = BootstrapPubspecStage(moduleConfigService),
        _registerWorkspace = RegisterWorkspaceStage(workspaceRoot);

  final ValidateInputStage _validateInput;
  final ResolveTemplateStage _resolveTemplate;
  final CopyTemplateStage _copyTemplate;
  final BootstrapPubspecStage _bootstrapPubspec;
  final RegisterWorkspaceStage _registerWorkspace;

  Future<ModuleCreateContext> run(ModuleCreateContext context) {
    return StageRunner<ModuleCreateContext>(
      stages: <Stage<ModuleCreateContext>>[
        _validateInput,
        _resolveTemplate,
        _copyTemplate,
        _bootstrapPubspec,
        _registerWorkspace,
      ],
    ).run(context);
  }
}
