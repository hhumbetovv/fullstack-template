import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/feature/links/feature.dart';
import 'package:scripts/src/feature/links/services/link_creator.dart';

class PubspecLinksCommand extends ScriptsCommand {
  PubspecLinksCommand()
    : _orchestrator = LinksOrchestrator(linkCreator: const LinkCreator()),
      super(
        commandName: 'pubspec-links',
        commandDescription:
            'Create symlinks for pubspec.yaml files under yaml/pubspecs.',
      );

  final LinksOrchestrator _orchestrator;

  @override
  Future<int> runCommand() => _orchestrator.runPubspecLinks();
}
