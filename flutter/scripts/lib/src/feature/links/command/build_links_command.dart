import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/feature/links/feature.dart';

class BuildLinksCommand extends ScriptsCommand {
  BuildLinksCommand()
    : super(
        commandName: 'build-links',
        commandDescription:
            'Create symlinks for build.yaml files under yaml/builds.',
      );

  @override
  Future<int> runCommand() => runBuildLinksFeature();
}
