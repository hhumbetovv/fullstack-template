import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/feature/links/feature.dart';
import 'package:scripts/src/feature/links/services/link_creator.dart';

class BuildLinksCommand extends ScriptsCommand {
  BuildLinksCommand()
    : _orchestrator = LinksOrchestrator(linkCreator: const LinkCreator()),
      super(
        commandName: 'build-links',
        commandDescription:
            'Create symlinks for build.yaml files under yaml/builds.',
      );

  final LinksOrchestrator _orchestrator;

  @override
  Future<int> runCommand() => _orchestrator.runBuildLinks();
}
