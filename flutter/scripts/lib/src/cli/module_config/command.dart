import 'package:args/command_runner.dart';
import 'package:scripts/src/application/module_config/module_config_executor.dart';
import 'package:scripts/src/core/command/base_command.dart';
import 'package:scripts/src/core/di/dependency_setup.dart';
import 'package:scripts/src/domain/models/module_config.dart';

class ModuleConfigCommand extends ScriptsCommand {
  ModuleConfigCommand()
    : super(
        commandName: 'modules-sync',
        commandDescription: 'Update pubspec.yaml files from module.yaml specs.',
      ) {
    argParser
      ..addMultiOption(
        'modules',
        abbr: 'm',
        valueHelp: 'module',
        help:
            'Optional module names or paths to limit the sync. Defaults to all workspace modules.',
      )
      ..addMultiOption(
        'packages',
        abbr: 'p',
        valueHelp: 'package',
        help: 'Only process modules that depend on the given packages.',
      )
      ..addFlag(
        'check',
        negatable: false,
        help: 'Dry-run: report which pubspec.yaml files would change.',
      )
      ..addFlag(
        'format',
        negatable: false,
        help:
            'Format module.yaml files and enforce sorted lists before syncing.',
      )
      ..addFlag(
        'lock',
        negatable: false,
        help:
            'Emit build_info/modules_lock.yaml with every module\'s resolved package versions.',
      )
      ..addFlag(
        'report',
        negatable: false,
        help:
            'Emit build_info/dependencies.md with a Markdown dependency report.',
      );
  }

  @override
  Future<int> runCommand() {
    configureDependencies();
    final modules = <String>[
      ...((argResults?['modules'] as List<String>?) ?? const <String>[]),
      ...((argResults?.rest ?? const <String>[])),
    ];
    final packages = <String>[
      ...(argResults?['packages'] as List<String>? ?? const <String>[]),
    ];
    final checkOnly = argResults?['check'] as bool? ?? false;
    final formatSpecs = argResults?['format'] as bool? ?? false;
    final generateLock = argResults?['lock'] as bool? ?? false;
    final generateReport = argResults?['report'] as bool? ?? false;

    if (checkOnly && (formatSpecs || generateLock || generateReport)) {
      throw UsageException(
        '--check cannot be combined with --format, --lock, or --report because those flags write files.',
        usage,
      );
    }

    final options = ModuleSyncOptions(
      targets: modules,
      packageFilters: packages,
      checkOnly: checkOnly,
      formatSpecs: formatSpecs,
      generateLockFile: generateLock,
      generateReport: generateReport,
    );

    return getDependency<ModuleConfigExecutor>().run(options: options);
  }
}
