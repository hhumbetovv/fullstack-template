import 'package:scripts/src/core/core.dart';

import '../feature.dart';

class PubspecLinksCommand extends ScriptsCommand {
  PubspecLinksCommand()
    : super(
        commandName: 'pubspec-links',
        commandDescription:
            'Create symlinks for pubspec.yaml files under yaml/pubspecs.',
      );

  @override
  Future<int> runCommand() => runPubspecLinksFeature();
}
