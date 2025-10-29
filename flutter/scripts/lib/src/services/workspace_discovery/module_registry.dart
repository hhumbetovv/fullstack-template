part of 'package:scripts/src/services/workspace_discovery_service.dart';

void _registerModule(
  String moduleName,
  String cleanPath,
  bool usesBuildRunner,
  bool wasKnownModule,
) {
  state.allModulePaths[moduleName] = cleanPath;

  if (!usesBuildRunner) {
    if (state.verbose && !wasKnownModule) {
      Logger.verbose('ℹ️  Module (no build_runner): $moduleName → $cleanPath');
    }
    return;
  }

  state.modulePaths[moduleName] = cleanPath;
  state.moduleBuildStatus[moduleName] = BuildStatus.pending;

  Logger.verbose('✅ Module found: $moduleName → $cleanPath');
}
