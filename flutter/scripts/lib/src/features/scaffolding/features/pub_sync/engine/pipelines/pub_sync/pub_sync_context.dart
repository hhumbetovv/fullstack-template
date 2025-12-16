import 'package:scripts/src/features/scaffolding/domain/models/module_config.dart';

class PubSyncContext {
  PubSyncContext({required this.options});

  final ModuleSyncOptions options;
  ModuleSyncSummary? summary;
  int exitCode = 0;
}
