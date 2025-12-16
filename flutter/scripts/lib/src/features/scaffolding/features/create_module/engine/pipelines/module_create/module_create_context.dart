import 'dart:io';

/// Context shared across create-module stages.
class ModuleCreateContext {
  ModuleCreateContext({
    required this.featurePath,
    required this.moduleType,
    required this.workspaceRoot,
  });

  final String featurePath;
  final String moduleType;
  final String workspaceRoot;

  late List<String> featureSegments;
  late String normalizedModuleType;
  late String moduleName;
  late Directory moduleDir;
  late Directory templateDir;
  late Map<String, String> replacements;

  int exitCode = 0;
}
