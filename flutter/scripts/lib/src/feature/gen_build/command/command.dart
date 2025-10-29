import 'package:scripts/src/core/core.dart';

import '../feature.dart';

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
