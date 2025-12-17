import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/core/config/scripts_config.dart';
import 'package:scripts/src/core/di/dependency_setup.dart';
import 'package:scripts/src/features/build_engine/features/codegen/commands/gen_build/gen_executor.dart';

class GenCleanCommand extends ScriptsCommand {
  GenCleanCommand()
    : super(
        commandName: 'gen-clean',
        commandDescription:
            'Run build_runner clean for all modules with build_runner.',
      ) {
    argParser.addOption(
      'workers',
      abbr: 'w',
      help: 'Maximum number of concurrent clean jobs (auto uses CPU count).',
      valueHelp: 'count',
      defaultsTo: CodegenGenCleanConfig.defaultWorkers,
    );
  }

  @override
  Future<int> runCommand() async {
    final workers =
        argResults?['workers'] as String? ?? CodegenGenCleanConfig.defaultWorkers;
    configureDependencies();
    return getDependency<GenExecutor>().runClean(workers);
  }
}
