import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/feature/gen_watch/feature.dart';
import 'package:scripts/src/feature/smart_build/runner/runner.dart';
import 'package:scripts/src/services/build_runner_service.dart';
import 'package:scripts/src/services/workspace_service.dart';

class GenWatchCommand extends ScriptsCommand {
  GenWatchCommand()
    : _orchestrator = GenWatchOrchestrator(
        workspaceService: const WorkspaceService(),
        buildRunnerService: const BuildRunnerService(),
        smartBuildRunner: runSmartBuild,
      ),
      super(
        commandName: 'gen-watch',
        commandDescription:
            'Run build_runner watch for modules, optionally limited to specific names.',
      ) {
    argParser.addFlag(
      'pre-build',
      help: 'Run smart-build before starting watchers.',
      negatable: false,
    );
  }

  final GenWatchOrchestrator _orchestrator;

  @override
  Future<int> runCommand() async {
    final preBuild = argResults?['pre-build'] as bool? ?? false;
    return _orchestrator.run(
      preBuild: preBuild,
      filters: argResults?.rest ?? const [],
    );
  }
}
