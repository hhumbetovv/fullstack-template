import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/feature/gen_build/feature.dart';
import 'package:scripts/src/services/build_runner_service.dart';
import 'package:scripts/src/services/workspace_service.dart';

class GenBuildCommand extends ScriptsCommand {
  GenBuildCommand()
    : _orchestrator = GenBuildOrchestrator(
        workspaceService: const WorkspaceService(),
        buildRunnerService: const BuildRunnerService(),
      ),
      super(
        commandName: 'gen-build',
        commandDescription:
            'Run build_runner build for modules that depend on it.',
      );

  final GenBuildOrchestrator _orchestrator;

  @override
  Future<int> runCommand() => _orchestrator.run(argResults?.rest ?? const []);
}
