import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/core/di/dependency_setup.dart';
import 'package:scripts/src/features/build_engine/features/codegen/commands/gen_build/gen_executor.dart';

class GenWatchCommand extends ScriptsCommand {
  GenWatchCommand()
    : super(
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

  @override
  Future<int> runCommand() async {
    final preBuild = argResults?['pre-build'] as bool? ?? false;
    configureDependencies();
    return getDependency<GenExecutor>().runWatch(
      preBuild: preBuild,
      filters: argResults?.rest ?? const [],
    );
  }
}
