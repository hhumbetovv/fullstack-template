import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/feature/links/feature.dart';

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
