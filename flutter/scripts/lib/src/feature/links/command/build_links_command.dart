import 'package:scripts/src/core/core.dart';

import '../feature.dart';

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
