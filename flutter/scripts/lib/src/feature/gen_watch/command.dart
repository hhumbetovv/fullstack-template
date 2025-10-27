import 'package:scripts/src/core/core.dart';

import 'gen_watch_feature.dart';

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
    return runGenWatchFeature(
      preBuild: preBuild,
      filters: argResults?.rest ?? const [],
    );
  }
}
