import 'dart:io';

import 'package:path/path.dart' as p;

class WorkspaceModuleVersions {
  const WorkspaceModuleVersions({
    required this.dartSdk,
    required this.packageVersions,
  });

  final String dartSdk;
  final Map<String, String> packageVersions;

  String? versionFor(String packageName) => packageVersions[packageName];
}

class ModuleSpec {
  ModuleSpec({
    required this.name,
    required this.directory,
    required this.dependencies,
    required this.devDependencies,
    required this.modules,
    required this.devModules,
  });

  final String name;
  final Directory directory;
  final List<String> dependencies;
  final List<String> devDependencies;
  final List<String> modules;
  final List<String> devModules;

  File get moduleConfigFile => File(p.join(directory.path, 'module.yaml'));
  File get pubspecFile => File(p.join(directory.path, 'pubspec.yaml'));
}

class ModuleSyncOptions {
  const ModuleSyncOptions({
    this.targets = const [],
    this.packageFilters = const [],
    this.checkOnly = false,
    this.formatSpecs = false,
    this.generateLockFile = false,
    this.generateReport = false,
  });

  final List<String> targets;
  final List<String> packageFilters;
  final bool checkOnly;
  final bool formatSpecs;
  final bool generateLockFile;
  final bool generateReport;

  bool get hasTargetFilters => targets.isNotEmpty;
  bool get hasPackageFilters => packageFilters.isNotEmpty;
}

class ModuleDependencySnapshot {
  ModuleDependencySnapshot({
    required this.name,
    required this.moduleDependencies,
    required this.packageDependencies,
    required this.devModuleDependencies,
    required this.devPackageDependencies,
  });

  final String name;
  final List<String> moduleDependencies;
  final Map<String, String> packageDependencies;
  final List<String> devModuleDependencies;
  final Map<String, String> devPackageDependencies;
}

class ModuleSyncSummary {
  ModuleSyncSummary({
    required this.changed,
    required this.unchanged,
    required this.formatted,
    required this.failures,
    required this.lockFilePath,
    required this.reportFilePath,
    required this.checkMode,
  });

  final List<String> changed;
  final List<String> unchanged;
  final List<String> formatted;
  final Map<String, String> failures;
  final String? lockFilePath;
  final String? reportFilePath;
  final bool checkMode;

  bool get hasFailures => failures.isNotEmpty;
  bool get hasChanges => changed.isNotEmpty;
}
