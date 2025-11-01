import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/feature/gen_build/feature.dart';

class GenBuildCommand extends ScriptsCommand {
  GenBuildCommand()
    : super(
        commandName: 'gen-build',
        commandDescription:
            'Run build_runner build for modules that depend on it.',
      );

  @override
  Future<int> runCommand() => runGenBuildFeature(argResults?.rest ?? const []);
}
