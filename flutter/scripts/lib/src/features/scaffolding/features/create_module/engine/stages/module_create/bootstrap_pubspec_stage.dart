import 'package:path/path.dart' as p;
import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/scaffolding/domain/adapters/module_config_service.dart';
import 'package:scripts/src/features/scaffolding/domain/models/module_config.dart';
import 'package:scripts/src/features/scaffolding/features/create_module/engine/pipelines/module_create/module_create_context.dart';

class BootstrapPubspecStage implements Stage<ModuleCreateContext> {
  BootstrapPubspecStage(this._moduleConfigService);

  final ModuleConfigService _moduleConfigService;

  @override
  String get name => 'bootstrap-pubspec';

  @override
  Future<ModuleCreateContext> run(ModuleCreateContext context) async {
    final relativePath =
        p.relative(context.moduleDir.path, from: context.workspaceRoot);
    final summary = await _moduleConfigService.syncModules(
      options: ModuleSyncOptions(
        checkOnly: false,
        targets: [relativePath],
        packageFilters: const [],
        formatSpecs: false,
        generateLockFile: false,
        generateReport: false,
        reverse: false,
        forceAll: true,
      ),
    );

    if (summary.hasFailures) {
      final messages = StringBuffer()
        ..writeln('Failed to bootstrap pubspec for $relativePath');
      summary.failures.forEach((moduleName, message) {
        messages.writeln('  $moduleName: $message');
      });
      throw CommandError(messages.toString(), exitCode: 1);
    }
    return context;
  }
}
