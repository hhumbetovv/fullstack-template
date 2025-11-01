import 'package:scripts/src/application/gen/gen_executor.dart';
import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/core/di/dependency_setup.dart';

class GenBuildCommand extends ScriptsCommand {
  GenBuildCommand()
    : super(
        commandName: 'gen-build',
        commandDescription:
            'Run build_runner build for modules that depend on it.',
      );

  @override
  Future<int> runCommand() {
    configureDependencies();
    return getDependency<GenExecutor>().runBuild(argResults?.rest ?? const []);
  }
}
