import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/feature/gen_clean/feature.dart';

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
      defaultsTo: 'auto',
    );
  }

  @override
  Future<int> runCommand() async {
    final workers = argResults?['workers'] as String? ?? 'auto';
    return runGenCleanFeature(workers);
  }
}
