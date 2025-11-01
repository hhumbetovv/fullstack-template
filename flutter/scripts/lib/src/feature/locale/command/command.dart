import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/feature/locale/feature.dart';

class LocaleCommand extends ScriptsCommand {
  LocaleCommand()
    : _orchestrator = const LocaleOrchestrator(),
      super(
        commandName: 'locale',
        commandDescription:
            'Generate locale key constants from translation JSON files.',
      ) {
    argParser
      ..addOption(
        'input',
        defaultsTo: 'app/assets/translations',
        help: 'Directory containing translation JSON files.',
      )
      ..addOption(
        'output',
        defaultsTo: 'common/lib/src/constants/locale_keys.dart',
        help: 'Path for the generated Dart file.',
      );
  }

  final LocaleOrchestrator _orchestrator;

  @override
  Future<int> runCommand() async {
    final inputPath =
        argResults?['input'] as String? ?? 'app/assets/translations';
    final outputPath =
        argResults?['output'] as String? ??
        'common/lib/src/constants/locale_keys.dart';
    return _orchestrator.run(
      inputPath: inputPath,
      outputPath: outputPath,
    );
  }
}
