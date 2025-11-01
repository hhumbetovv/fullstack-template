import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/feature/gen/feature.dart';
import 'package:scripts/src/feature/smart_build/runner/runner.dart';
import 'package:scripts/src/services/build_runner_service.dart';
import 'package:scripts/src/services/workspace_service.dart';

class GenCleanCommand extends ScriptsCommand {
  GenCleanCommand()
    : _feature = GenFeature(
        workspaceService: const WorkspaceService(),
        buildRunnerService: const BuildRunnerService(),
        smartBuildRunner: runSmartBuild,
      ),
      super(
        commandName: 'gen-clean',
        commandDescription:
            'Run build_runner clean for all modules with build_runner.',
      ) {
    argParser.addOption(
      'workers',
      abbr: 'w',
      help: 'Maximum number of concurrent clean jobs (auto uses CPU count).',
      valueHelp: 'count',
      defaultsTo: 'auto',
    );
  }

  final GenFeature _feature;

  @override
  Future<int> runCommand() async {
    final workers = argResults?['workers'] as String? ?? 'auto';
    return _feature.runClean(workers);
  }
}
