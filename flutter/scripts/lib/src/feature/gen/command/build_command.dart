import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/feature/gen/feature.dart';
import 'package:scripts/src/feature/smart_build/runner/runner.dart';
import 'package:scripts/src/services/build_runner_service.dart';
import 'package:scripts/src/services/workspace_service.dart';

class GenBuildCommand extends ScriptsCommand {
  GenBuildCommand()
    : _feature = GenFeature(
        workspaceService: const WorkspaceService(),
        buildRunnerService: const BuildRunnerService(),
        smartBuildRunner: runSmartBuild,
      ),
      super(
        commandName: 'gen-build',
        commandDescription:
            'Run build_runner build for modules that depend on it.',
      );

  final GenFeature _feature;

  @override
  Future<int> runCommand() => _feature.runBuild(argResults?.rest ?? const []);
}
