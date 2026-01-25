import 'dart:collection';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/config/scripts_config.dart';
import 'package:scripts/src/features/scaffolding/domain/models/module_config.dart';
import 'package:scripts/src/features/scaffolding/domain/models/yaml_include.dart';
import 'package:scripts/src/features/scaffolding/engine/services/yaml_service.dart';
import 'package:scripts/src/features/scaffolding/engine/services/yaml_writer.dart';
import 'package:tools_common/tooling.dart' show normalizeLineEndings, preferredLineEndingForContent;
import 'package:yaml/yaml.dart';

const _moduleSpecReservedKeys = <String>{
  'name',
  'modules',
  'dev_modules',
  'dependencies',
  'dev_dependencies',
  'environment',
  'resolution',
  'build',
};

const _managedPubspecKeys = <String>{
  'name',
  'dependencies',
  'dev_dependencies',
  'environment',
  'resolution',
};

class ModuleConfigService {
  ModuleConfigService({
    String? workspaceConfigFile,
    String? rootPubspecFile,
    String? lockFilePath,
    String? dependencyReportPath,
  }) : workspaceConfigFile = workspaceConfigFile ?? ScaffoldingConfig.workspaceConfigFile,
       rootPubspecFile = rootPubspecFile ?? ScaffoldingConfig.rootPubspecFile,
       lockFilePath = lockFilePath ?? ScaffoldingConfig.lockFilePath,
       dependencyReportPath = dependencyReportPath ?? ScaffoldingConfig.dependencyReportPath;

  final String workspaceConfigFile;
  final String rootPubspecFile;
  final String lockFilePath;
  final String dependencyReportPath;
  final Directory _root = Directory.current;

  Future<ModuleSyncSummary> syncModules({
    required ModuleSyncOptions options,
  }) async {
    final workspaceEntries = _augmentWorkspaceEntries(
      await _loadWorkspaceEntries(),
      options.targets,
    );
    if (options.reverse) {
      return _syncModuleSpecsFromPubspecs(
        workspaceEntries: workspaceEntries,
        options: options,
      );
    }

    final versions = _loadWorkspaceVersions();
    return _syncPubspecsFromModuleSpecs(
      workspaceEntries: workspaceEntries,
      options: options,
      versions: versions,
    );
  }

  Future<ModuleSyncSummary> _syncPubspecsFromModuleSpecs({
    required List<String> workspaceEntries,
    required ModuleSyncOptions options,
    required WorkspaceModuleVersions versions,
  }) async {
    final modules = <ModuleSpec>[];
    final failures = <String, String>{};

    for (final entry in workspaceEntries) {
      final absolutePath = p.normalize(p.join(_root.path, entry));
      final directory = Directory(absolutePath);
      if (!directory.existsSync()) {
        failures[entry] = 'Directory not found: $absolutePath';
        continue;
      }
      try {
        modules.add(_readModuleSpec(directory));
      } on CommandError catch (error) {
        failures[entry] = error.message;
      }
    }

    final moduleNames = modules.map((module) => module.name).toSet();
    var filtered = _filterModules(modules, options.targets, failures);
    filtered = _filterModulesByPackages(filtered, options.packageFilters);

    final changed = <String>[];
    final unchanged = <String>[];
    final formatted = <String>[];
    final snapshots = <ModuleDependencySnapshot>[];
    final pubspecChanges = <ModulePubspecChange>[];
    final buildChanges = <ModuleBuildChange>[];

    for (final module in filtered) {
      final missingModuleDeps = _missingModuleDependencies(module, moduleNames);
      if (missingModuleDeps.isNotEmpty) {
        failures[module.name] = 'Unknown modules: ${missingModuleDeps.join(', ')} (add them to the workspace)';
        continue;
      }

      final unknownPackages = _unknownPackages(module, versions);
      if (unknownPackages.isNotEmpty) {
        failures[module.name] =
            'Unknown packages: ${unknownPackages.join(', ')} (add versions to $workspaceConfigFile)';
        continue;
      }

      if (options.formatSpecs) {
        final formattedModule = _formatModuleSpec(module);
        if (formattedModule) {
          formatted.add(module.name);
        }
      }

      try {
        final pubspecResult = await _processModule(
          module: module,
          versions: versions,
          checkOnly: options.checkOnly,
          forceWrite: options.forceAll,
        );
        final buildResult = _processBuildFile(
          module: module,
          checkOnly: options.checkOnly,
          forceWrite: options.forceAll,
        );
        snapshots.add(pubspecResult.snapshot);

        final moduleChanged = pubspecResult.changed || buildResult.changed;
        if (moduleChanged) {
          changed.add(module.name);
        } else {
          unchanged.add(module.name);
        }

        if (pubspecResult.changed) {
          pubspecChanges.add(
            ModulePubspecChange(
              moduleName: module.name,
              directoryPath: module.directory.path,
              pubspecPath: module.pubspecFile.path,
              previousContent: pubspecResult.previousContent,
              hadExistingFile: pubspecResult.hadExistingPubspec,
            ),
          );
        }

        if (buildResult.changed) {
          buildChanges.add(
            ModuleBuildChange(
              moduleName: module.name,
              directoryPath: module.directory.path,
              buildFilePath: module.buildFile.path,
              previousContent: buildResult.previousContent,
              hadExistingFile: buildResult.hadExistingBuild,
            ),
          );
        }
      } on CommandError catch (error) {
        failures[module.name] = error.message;
      } on Object catch (error) {
        failures[module.name] = 'Unexpected error: $error';
      }
    }

    final lockPath = options.generateLockFile ? _writeLockFile(snapshots, versions.dartSdk) : null;
    final reportPath = options.generateReport ? _writeDependencyReport(snapshots) : null;

    return ModuleSyncSummary(
      changed: changed,
      unchanged: unchanged,
      formatted: formatted,
      failures: failures,
      lockFilePath: lockPath,
      reportFilePath: reportPath,
      checkMode: options.checkOnly,
      workspaceConfigChanged: false,
      workspaceConfigPath: null,
      pubspecChanges: pubspecChanges,
      buildChanges: buildChanges,
    );
  }

  Future<ModuleSyncSummary> _syncModuleSpecsFromPubspecs({
    required List<String> workspaceEntries,
    required ModuleSyncOptions options,
  }) async {
    final failures = <String, String>{};
    final rawEntries = await _loadModulePubspecs(workspaceEntries, failures);
    final moduleNames = rawEntries.map((entry) => entry.name).toSet();
    final workspaceResult = await _ensureWorkspaceConfigFile(
      modules: rawEntries,
      workspaceModuleNames: moduleNames,
      failures: failures,
      checkOnly: options.checkOnly,
    );
    final modules = rawEntries
        .map(
          (entry) => _buildModuleSpecFromPubspec(
            data: entry,
            workspaceModuleNames: moduleNames,
          ),
        )
        .toList();

    var filtered = _filterModules(modules, options.targets, failures);
    filtered = _filterModulesByPackages(filtered, options.packageFilters);

    final changed = <String>[];
    final unchanged = <String>[];

    for (final module in filtered) {
      final missingModuleDeps = _missingModuleDependencies(module, moduleNames);
      if (missingModuleDeps.isNotEmpty) {
        failures[module.name] = 'Unknown modules: ${missingModuleDeps.join(', ')} (add them to the workspace)';
        continue;
      }

      final didChange = _writeModuleYamlFromSpec(
        module,
        checkOnly: options.checkOnly,
      );
      if (didChange) {
        changed.add(module.name);
      } else {
        unchanged.add(module.name);
      }
    }

    return ModuleSyncSummary(
      changed: changed,
      unchanged: unchanged,
      formatted: const <String>[],
      failures: failures,
      lockFilePath: null,
      reportFilePath: null,
      checkMode: options.checkOnly,
      workspaceConfigChanged: workspaceResult.changed,
      workspaceConfigPath: workspaceResult.path,
      pubspecChanges: const <ModulePubspecChange>[],
      buildChanges: const <ModuleBuildChange>[],
    );
  }

  List<String> _missingModuleDependencies(
    ModuleSpec module,
    Set<String> workspaceModules,
  ) {
    final missing = <String>{};
    void collect(List<String> modulesList) {
      for (final dependency in modulesList) {
        if (!workspaceModules.contains(dependency)) {
          missing.add(dependency);
        }
      }
    }

    collect(module.modules);
    collect(module.devModules);
    final result = missing.toList()..sort();
    return result;
  }

  Future<_WorkspaceConfigResult> _ensureWorkspaceConfigFile({
    required List<_ModulePubspecData> modules,
    required Set<String> workspaceModuleNames,
    required Map<String, String> failures,
    required bool checkOnly,
  }) async {
    final workspacePath = p.join(_root.path, workspaceConfigFile);
    final file = File(workspacePath);
    if (file.existsSync()) {
      return const _WorkspaceConfigResult(changed: false, path: null);
    }

    final dartSdk = await _readRootDartSdkConstraint();
    if (dartSdk == null || dartSdk.isEmpty) {
      failures[workspaceConfigFile] = 'Cannot infer `dart_sdk` constraint from $rootPubspecFile';
      return const _WorkspaceConfigResult(changed: false, path: null);
    }

    final packages = SplayTreeMap<String, String>();
    final missingVersions = <String>{};
    final conflicts = <String, Set<String>>{};

    void collect(dynamic dependencies, String owner) {
      if (dependencies is! Map) return;
      dependencies.forEach((dynamic rawName, dynamic spec) {
        final packageName = rawName?.toString().trim();
        if (packageName == null ||
            packageName.isEmpty ||
            packageName == owner ||
            workspaceModuleNames.contains(packageName) ||
            _isFlutterSdkPackage(packageName)) {
          return;
        }
        final version = _dependencyVersionString(spec);
        if (version == null || version.isEmpty) {
          missingVersions.add(packageName);
          return;
        }
        final existing = packages[packageName];
        if (existing != null && existing != version) {
          conflicts.putIfAbsent(packageName, () => <String>{})
            ..add(existing)
            ..add(version);
          return;
        }
        packages[packageName] = version;
      });
    }

    for (final module in modules) {
      collect(module.pubspec['dependencies'], module.name);
      collect(module.pubspec['dev_dependencies'], module.name);
    }

    const writer = YamlWriter(
      preferredOrder: [
        'dart_sdk',
        'packages',
      ],
    );
    final content =
        '${writer.convert(<String, dynamic>{
          'dart_sdk': dartSdk,
          'packages': packages,
        })}\n';

    if (!checkOnly) {
      final normalized = normalizeLineEndings(
        content,
        preferredLineEnding: preferredLineEndingForContent(null),
      );
      file.writeAsStringSync(normalized);
    }

    if (missingVersions.isNotEmpty || conflicts.isNotEmpty) {
      final messages = <String>[];
      if (missingVersions.isNotEmpty) {
        final missing = missingVersions.toList()..sort();
        messages.add(
          'Missing versions for packages: ${missing.join(', ')}.',
        );
      }
      if (conflicts.isNotEmpty) {
        final conflictMessages = conflicts.entries.map((entry) {
          final versions = entry.value.toList()..sort();
          return '${entry.key} (${versions.join(' vs ')})';
        }).toList()..sort();
        messages.add(
          'Conflicting versions detected: ${conflictMessages.join(', ')}.',
        );
      }
      failures[workspaceConfigFile] = messages.join(' ');
    }

    return _WorkspaceConfigResult(
      changed: true,
      path: workspaceConfigFile,
    );
  }

  Future<String?> _readRootDartSdkConstraint() async {
    final pubspec = await readPubspec(p.join(_root.path, rootPubspecFile));
    final environment = pubspec?['environment'];
    if (environment is! Map) return null;
    final dartSdk = environment['sdk']?.toString();
    return dartSdk;
  }

  Future<List<_ModulePubspecData>> _loadModulePubspecs(
    List<String> workspaceEntries,
    Map<String, String> failures,
  ) async {
    final modules = <_ModulePubspecData>[];
    for (final entry in workspaceEntries) {
      final absolutePath = p.normalize(p.join(_root.path, entry));
      final directory = Directory(absolutePath);
      if (!directory.existsSync()) {
        failures[entry] = 'Directory not found: $absolutePath';
        continue;
      }

      final relative = p.relative(directory.path, from: _root.path);
      final pubspecFile = File(p.join(directory.path, 'pubspec.yaml'));
      if (!pubspecFile.existsSync()) {
        failures[relative] = 'pubspec.yaml not found for $relative';
        continue;
      }

      final pubspec = await readPubspec(pubspecFile.path);
      if (pubspec == null) {
        failures[relative] = 'Failed to parse ${pubspecFile.path}';
        continue;
      }

      final name = pubspec['name']?.toString();
      if (name == null || name.isEmpty) {
        failures[relative] = '`name` missing in ${pubspecFile.path}';
        continue;
      }

      dynamic existingBuildConfig;
      final moduleConfigFile = File(p.join(directory.path, 'module.yaml'));
      if (moduleConfigFile.existsSync()) {
        try {
          final moduleData = _readYaml(moduleConfigFile);
          existingBuildConfig = moduleData['build'];
        } on CommandError {
          existingBuildConfig = null;
        }
      }

      modules.add(
        _ModulePubspecData(
          name: name,
          directory: directory,
          pubspec: pubspec,
          buildConfig: existingBuildConfig,
        ),
      );
    }
    return modules;
  }

  ModuleSpec _buildModuleSpecFromPubspec({
    required _ModulePubspecData data,
    required Set<String> workspaceModuleNames,
  }) {
    final dependencyBreakdown = _splitDependenciesFromPubspec(
      data.pubspec['dependencies'],
      workspaceModuleNames,
      data.name,
    );
    final devDependencyBreakdown = _splitDependenciesFromPubspec(
      data.pubspec['dev_dependencies'],
      workspaceModuleNames,
      data.name,
    );

    final additionalFields = Map<String, dynamic>.from(data.pubspec)
      ..removeWhere((key, _) => _managedPubspecKeys.contains(key));

    return ModuleSpec(
      name: data.name,
      directory: data.directory,
      dependencies: dependencyBreakdown.packages,
      devDependencies: devDependencyBreakdown.packages,
      modules: dependencyBreakdown.modules,
      devModules: devDependencyBreakdown.modules,
      buildConfig: data.buildConfig,
      additionalFields: additionalFields,
    );
  }

  _DependencyBreakdown _splitDependenciesFromPubspec(
    dynamic dependencies,
    Set<String> workspaceModuleNames,
    String currentModuleName,
  ) {
    if (dependencies is! Map) {
      return const _DependencyBreakdown();
    }

    final moduleSet = <String>{};
    final packageSet = <String>{};
    dependencies.forEach((dynamic key, dynamic _) {
      final name = key?.toString().trim();
      if (name == null || name.isEmpty || name == currentModuleName) {
        return;
      }
      if (workspaceModuleNames.contains(name)) {
        moduleSet.add(name);
      } else {
        packageSet.add(name);
      }
    });

    return _DependencyBreakdown(
      modules: moduleSet.toList()..sort(),
      packages: packageSet.toList()..sort(),
    );
  }

  bool _writeModuleYamlFromSpec(ModuleSpec module, {required bool checkOnly}) {
    final file = module.moduleConfigFile;
    final data = <String, dynamic>{
      'name': module.name,
      'modules': List<String>.from(module.modules)..sort(),
      'dev_modules': List<String>.from(module.devModules)..sort(),
      'dependencies': List<String>.from(module.dependencies)..sort(),
      'dev_dependencies': List<String>.from(module.devDependencies)..sort(),
      if (module.buildConfig != null) 'build': module.buildConfig,
      ...module.additionalFields,
    };

    final writer = YamlWriter(
      preferredOrder: _moduleYamlOrder(module.additionalFields.keys),
    );

    final content = '${writer.convert(data)}\n';
    final existingContent = file.existsSync() ? file.readAsStringSync() : null;
    final existing = existingContent?.trimRight() ?? '';
    final changed = existing != content.trimRight();

    if (!checkOnly && changed) {
      final normalized = normalizeLineEndings(
        content,
        preferredLineEnding: preferredLineEndingForContent(existingContent),
      );
      file.writeAsStringSync(normalized);
    }

    return changed;
  }

  WorkspaceModuleVersions _loadWorkspaceVersions() {
    final file = File(p.join(_root.path, workspaceConfigFile));
    if (!file.existsSync()) {
      throw CommandError(
        'Workspace config not found at ${file.path}',
        exitCode: 66,
      );
    }
    final yaml = _readYaml(file);
    final dartSdk = yaml['dart_sdk']?.toString();
    if (dartSdk == null || dartSdk.isEmpty) {
      throw const CommandError(
        '`dart_sdk` missing from pub_versions.yaml',
        exitCode: 66,
      );
    }

    final packages = <String, String>{};
    final rawPackages = yaml['packages'];
    if (rawPackages is Map<String, dynamic>) {
      for (final entry in rawPackages.entries) {
        packages[entry.key] = entry.value.toString();
      }
    } else {
      throw const CommandError(
        '`packages` section missing from workspace config.',
        exitCode: 66,
      );
    }

    return WorkspaceModuleVersions(
      dartSdk: dartSdk,
      packageVersions: packages,
    );
  }

  Future<List<String>> _loadWorkspaceEntries() async {
    final pubspec = await readPubspec(p.join(_root.path, rootPubspecFile));
    if (pubspec == null) {
      throw CommandError(
        'Root pubspec.yaml not found at ${p.join(_root.path, rootPubspecFile)}',
        exitCode: 66,
      );
    }

    final workspace = pubspec['workspace'];
    if (workspace is! List) {
      throw const CommandError(
        'Root pubspec.yaml is missing workspace entries.',
        exitCode: 66,
      );
    }

    final entries = <String>[];
    for (final entry in workspace) {
      final path = entry?.toString().trim();
      if (path == null || path.isEmpty) continue;
      entries.add(path);
    }
    return entries;
  }

  List<String> _augmentWorkspaceEntries(
    List<String> workspaceEntries,
    List<String> targets,
  ) {
    if (targets.isEmpty) {
      return workspaceEntries;
    }

    final seen = workspaceEntries.toSet();
    for (final target in targets) {
      final path = _resolveTargetPath(target);
      if (path != null && seen.add(path)) {
        workspaceEntries.add(path);
      }
    }
    return workspaceEntries;
  }

  String? _resolveTargetPath(String target) {
    final trimmed = target.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final absolutePath = p.isAbsolute(trimmed) ? p.normalize(trimmed) : p.normalize(p.join(_root.path, trimmed));
    final directory = Directory(absolutePath);
    if (!directory.existsSync()) {
      return null;
    }
    final relative = p.relative(directory.path, from: _root.path);
    return relative;
  }

  ModuleSpec _readModuleSpec(Directory directory) {
    final configFile = File(p.join(directory.path, 'module.yaml'));
    if (!configFile.existsSync()) {
      final relative = p.relative(directory.path, from: _root.path);
      throw CommandError('module.yaml not found for $relative');
    }

    final data = _readYaml(configFile);
    final name = data['name']?.toString();
    if (name == null || name.isEmpty) {
      throw CommandError('`name` missing in ${configFile.path}');
    }
    final buildConfig = data['build'];
    final additionalFields = Map<String, dynamic>.from(data)
      ..removeWhere((key, _) => _moduleSpecReservedKeys.contains(key));

    return ModuleSpec(
      name: name,
      directory: directory,
      buildConfig: buildConfig,
      additionalFields: additionalFields,
      dependencies: _stringList(
        data['dependencies'],
        configFile.path,
        'dependencies',
      ),
      devDependencies: _stringList(
        data['dev_dependencies'],
        configFile.path,
        'dev_dependencies',
      ),
      modules: _stringList(data['modules'], configFile.path, 'modules'),
      devModules: _stringList(
        data['dev_modules'],
        configFile.path,
        'dev_modules',
      ),
    );
  }

  List<String> _stringList(dynamic value, String file, String field) {
    final resolved = _normalizeValue(value);
    if (resolved == null) return <String>[];
    if (resolved is List) {
      final result = <String>[];
      final seen = <String>{};
      for (final item in resolved) {
        final entry = item?.toString().trim();
        if (entry == null || entry.isEmpty) continue;
        if (seen.add(entry)) {
          result.add(entry);
        }
      }
      return result;
    }
    throw CommandError('`$field` must be a list in $file');
  }

  List<ModuleSpec> _filterModules(
    List<ModuleSpec> modules,
    List<String> targets,
    Map<String, String> failures,
  ) {
    final cleanedTargets = targets.map((target) => target.trim()).where((target) => target.isNotEmpty).toList();
    if (cleanedTargets.isEmpty) {
      return modules;
    }

    final selected = <ModuleSpec>[];
    final seen = <String>{};
    for (final target in cleanedTargets) {
      ModuleSpec? match;
      for (final module in modules) {
        if (_matches(module, target)) {
          match = module;
          break;
        }
      }
      if (match == null) {
        failures[target] = 'Module not found';
        continue;
      }
      if (seen.add(match.name)) {
        selected.add(match);
      }
    }
    return selected;
  }

  List<ModuleSpec> _filterModulesByPackages(
    List<ModuleSpec> modules,
    List<String> packageFilters,
  ) {
    final cleaned = packageFilters.map((pkg) => pkg.trim()).where((pkg) => pkg.isNotEmpty).toSet();
    if (cleaned.isEmpty) {
      return modules;
    }

    return modules.where((module) {
      final packageSet = {
        ...module.dependencies,
        ...module.devDependencies,
      };
      return packageSet.any(cleaned.contains);
    }).toList();
  }

  bool _matches(ModuleSpec module, String target) {
    if (module.name == target) return true;

    final modulePath = p.normalize(module.directory.path);
    final absoluteTarget = p.normalize(p.join(_root.path, target));
    if (modulePath == absoluteTarget) return true;

    final relative = p.relative(modulePath, from: _root.path);
    final normalizedRelative = p.normalize(relative);
    final normalizedTarget = p.normalize(target);

    return normalizedRelative == normalizedTarget || relative == target || p.basename(relative) == target;
  }

  List<String> _unknownPackages(
    ModuleSpec module,
    WorkspaceModuleVersions versions,
  ) {
    final unknown = <String>[];
    final seen = <String>{};
    void collect(List<String> packages) {
      for (final package in packages) {
        if (!_isFlutterSdkPackage(package) && versions.versionFor(package) == null) {
          if (seen.add(package)) {
            unknown.add(package);
          }
        }
      }
    }

    collect(module.dependencies);
    collect(module.devDependencies);
    return unknown;
  }

  bool _formatModuleSpec(ModuleSpec module) {
    final file = module.moduleConfigFile;
    final sortedModules = List<String>.from(module.modules)..sort();
    final sortedDevModules = List<String>.from(module.devModules)..sort();
    final sortedDependencies = List<String>.from(module.dependencies)..sort();
    final sortedDevDependencies = List<String>.from(module.devDependencies)..sort();

    module.modules
      ..clear()
      ..addAll(sortedModules);
    module.devModules
      ..clear()
      ..addAll(sortedDevModules);
    module.dependencies
      ..clear()
      ..addAll(sortedDependencies);
    module.devDependencies
      ..clear()
      ..addAll(sortedDevDependencies);

    final data = <String, dynamic>{
      'name': module.name,
      'modules': module.modules,
      'dev_modules': module.devModules,
      'dependencies': module.dependencies,
      'dev_dependencies': module.devDependencies,
      if (module.buildConfig != null) 'build': module.buildConfig,
      ...module.additionalFields,
    };

    final writer = YamlWriter(
      preferredOrder: _moduleYamlOrder(module.additionalFields.keys),
    );
    final content = '${writer.convert(data)}\n';
    final existingContent = file.existsSync() ? file.readAsStringSync() : null;
    if ((existingContent?.trimRight() ?? '') == content.trimRight()) {
      return false;
    }
    final normalized = normalizeLineEndings(
      content,
      preferredLineEnding: preferredLineEndingForContent(existingContent),
    );
    file.writeAsStringSync(normalized);
    return true;
  }

  Future<_ModuleProcessResult> _processModule({
    required ModuleSpec module,
    required WorkspaceModuleVersions versions,
    required bool checkOnly,
    required bool forceWrite,
  }) async {
    final pubspecFile = module.pubspecFile;
    final pubspecExists = pubspecFile.existsSync();
    if (pubspecExists) {
      final parsed = await readPubspec(pubspecFile.path);
      if (parsed == null) {
        throw CommandError('Failed to parse ${pubspecFile.path}');
      }
    }
    final updated = Map<String, dynamic>.from(module.additionalFields);

    updated['name'] = module.name;
    updated['environment'] = <String, dynamic>{'sdk': versions.dartSdk};
    updated['resolution'] = 'workspace';

    updated['dependencies'] = _buildDependencyMap(
      moduleDependencies: module.modules,
      packageDependencies: module.dependencies,
      versions: versions,
    );

    final devDependencies = _buildDependencyMap(
      moduleDependencies: module.devModules,
      packageDependencies: module.devDependencies,
      versions: versions,
    );

    if (devDependencies.isEmpty) {
      updated.remove('dev_dependencies');
    } else {
      updated['dev_dependencies'] = devDependencies;
    }

    const writer = YamlWriter();
    final content = '${writer.convert(_normalizeMap(updated))}\n';
    final existingContent = pubspecExists ? pubspecFile.readAsStringSync() : null;
    final previousContent = existingContent;

    // Normalize both contents for comparison to avoid false positives from line ending differences
    final normalizedContent = normalizeLineEndings(
      content,
      preferredLineEnding: preferredLineEndingForContent(existingContent),
    );
    final normalizedExisting = existingContent != null
        ? normalizeLineEndings(
            existingContent,
            preferredLineEnding: preferredLineEndingForContent(existingContent),
          )
        : '';

    final hasDiff = normalizedExisting.trimRight() != normalizedContent.trimRight();
    final shouldWrite = forceWrite || hasDiff;

    if (!checkOnly && shouldWrite) {
      pubspecFile.parent.createSync(recursive: true);
      pubspecFile.writeAsStringSync(normalizedContent);
    }

    final snapshot = _buildSnapshot(module, versions);
    return _ModuleProcessResult(
      snapshot: snapshot,
      changed: shouldWrite,
      previousContent: previousContent,
      hadExistingPubspec: pubspecExists,
    );
  }

  _BuildFileResult _processBuildFile({
    required ModuleSpec module,
    required bool checkOnly,
    required bool forceWrite,
  }) {
    final buildSpec = module.buildConfig;
    if (buildSpec == null) {
      return const _BuildFileResult(changed: false);
    }

    final normalized = _normalizeValue(buildSpec);
    if (normalized == null) {
      return const _BuildFileResult(changed: false);
    }

    if (_isManualBuildConfig(normalized)) {
      return const _BuildFileResult(changed: false, manual: true);
    }

    if (normalized is! Map && normalized is! String) {
      throw CommandError(
        '`build` must be a map or string in ${module.moduleConfigFile.path}',
      );
    }

    final buildFile = module.buildFile;
    final hadExisting = buildFile.existsSync();
    final existingContent = hadExisting ? buildFile.readAsStringSync() : null;

    final serialized = _serializeBuildConfig(normalized);
    final withNewline = serialized.endsWith('\n') ? serialized : '$serialized\n';
    final normalizedExisting = existingContent != null
        ? normalizeLineEndings(
            existingContent,
            preferredLineEnding: preferredLineEndingForContent(existingContent),
          )
        : '';
    final normalizedNew = normalizeLineEndings(
      withNewline,
      preferredLineEnding: preferredLineEndingForContent(existingContent),
    );

    final hasDiff = normalizedExisting.trimRight() != normalizedNew.trimRight();
    final shouldWrite = forceWrite || hasDiff;

    if (!checkOnly && shouldWrite) {
      buildFile.parent.createSync(recursive: true);
      buildFile.writeAsStringSync(normalizedNew);
    }

    return _BuildFileResult(
      changed: shouldWrite,
      previousContent: existingContent,
      hadExistingBuild: hadExisting,
    );
  }

  bool _isManualBuildConfig(dynamic value) {
    if (value is Map) {
      final manual = value['manual'];
      if (manual is bool) {
        return manual;
      }
      if (manual != null) {
        final normalized = manual.toString().toLowerCase().trim();
        return normalized == 'true' || normalized == 'yes';
      }
    }
    return false;
  }

  String _serializeBuildConfig(dynamic value) {
    if (value is String) {
      return value;
    }
    if (value is Map<String, dynamic>) {
      const writer = YamlWriter(preserveInputOrder: true);
      return writer.convert(value);
    }
    if (value is Map) {
      final converted = <String, dynamic>{};
      value.forEach((dynamic key, dynamic entryValue) {
        converted[key.toString()] = entryValue;
      });
      const writer = YamlWriter(preserveInputOrder: true);
      return writer.convert(converted);
    }
    throw CommandError(
      'Unsupported `build` configuration. Expected map or string, got ${value.runtimeType}.',
    );
  }

  Map<String, dynamic> _buildDependencyMap({
    required List<String> moduleDependencies,
    required List<String> packageDependencies,
    required WorkspaceModuleVersions versions,
  }) {
    final map = <String, dynamic>{};
    for (final module in moduleDependencies) {
      map[module] = 'any';
    }
    for (final package in packageDependencies) {
      map[package] = _packageSpec(package, versions);
    }
    return map;
  }

  ModuleDependencySnapshot _buildSnapshot(
    ModuleSpec module,
    WorkspaceModuleVersions versions,
  ) {
    return ModuleDependencySnapshot(
      name: module.name,
      moduleDependencies: List<String>.from(module.modules)..sort(),
      devModuleDependencies: List<String>.from(module.devModules)..sort(),
      packageDependencies: _packageVersionMap(module.dependencies, versions),
      devPackageDependencies: _packageVersionMap(
        module.devDependencies,
        versions,
      ),
    );
  }

  Map<String, String> _packageVersionMap(
    List<String> packages,
    WorkspaceModuleVersions versions,
  ) {
    final map = <String, String>{};
    final sorted = List<String>.from(packages)..sort();
    for (final package in sorted) {
      map[package] = _packageVersionString(package, versions);
    }
    return map;
  }

  String _packageVersionString(
    String packageName,
    WorkspaceModuleVersions versions,
  ) {
    if (_isFlutterSdkPackage(packageName)) {
      return 'sdk:flutter';
    }
    final version = versions.versionFor(packageName);
    if (version == null) {
      throw CommandError(
        'Version for `$packageName` not found in $workspaceConfigFile',
      );
    }
    return version;
  }

  dynamic _packageSpec(String packageName, WorkspaceModuleVersions versions) {
    if (_isFlutterSdkPackage(packageName)) {
      return <String, String>{'sdk': 'flutter'};
    }
    final version = versions.versionFor(packageName);
    if (version == null) {
      throw CommandError(
        'Version for `$packageName` not found in $workspaceConfigFile',
      );
    }
    return version;
  }

  bool _isFlutterSdkPackage(String packageName) {
    return packageName == 'flutter' || packageName == 'flutter_test' || packageName == 'flutter_localizations';
  }

  String? _dependencyVersionString(dynamic spec) {
    if (spec is String) {
      return spec.trim();
    }
    if (spec is Map) {
      final version = spec['version']?.toString().trim();
      if (version != null && version.isNotEmpty) {
        return version;
      }
    }
    return null;
  }

  String _writeLockFile(
    List<ModuleDependencySnapshot> snapshots,
    String dartSdk,
  ) {
    final modules = snapshots
        .map(
          (snapshot) => <String, dynamic>{
            'name': snapshot.name,
            'dependencies': <String, dynamic>{
              'modules': snapshot.moduleDependencies,
              'packages': snapshot.packageDependencies,
            },
            'dev_dependencies': <String, dynamic>{
              'modules': snapshot.devModuleDependencies,
              'packages': snapshot.devPackageDependencies,
            },
          },
        )
        .toList();

    const writer = YamlWriter(
      preferredOrder: [
        'dart_sdk',
        'modules',
        'name',
        'dependencies',
        'dev_dependencies',
        'modules',
        'packages',
      ],
    );

    final content =
        '${writer.convert(<String, dynamic>{
          'dart_sdk': dartSdk,
          'modules': modules,
        })}\n';
    final outputPath = p.join(_root.path, lockFilePath);
    _ensureDirectory(outputPath);
    final outputFile = File(outputPath);
    final existingContent = outputFile.existsSync() ? outputFile.readAsStringSync() : null;
    final normalized = normalizeLineEndings(
      content,
      preferredLineEnding: preferredLineEndingForContent(existingContent),
    );
    outputFile.writeAsStringSync(normalized);
    return lockFilePath;
  }

  String? _writeDependencyReport(List<ModuleDependencySnapshot> snapshots) {
    final buffer = StringBuffer()
      ..writeln('# Module dependencies')
      ..writeln();

    if (snapshots.isEmpty) {
      buffer.writeln('No modules processed.');
    } else {
      final sorted = List<ModuleDependencySnapshot>.from(snapshots)..sort((a, b) => a.name.compareTo(b.name));
      for (final snapshot in sorted) {
        buffer
          ..writeln('## ${snapshot.name}')
          ..writeln();
        _writeDependencySection(
          buffer,
          title: 'Dependencies',
          modules: snapshot.moduleDependencies,
          packages: snapshot.packageDependencies,
        );
        _writeDependencySection(
          buffer,
          title: 'Dev dependencies',
          modules: snapshot.devModuleDependencies,
          packages: snapshot.devPackageDependencies,
        );
      }
    }

    final outputPath = p.join(_root.path, dependencyReportPath);
    _ensureDirectory(outputPath);
    final outputFile = File(outputPath);
    final existingContent = outputFile.existsSync() ? outputFile.readAsStringSync() : null;
    final normalized = normalizeLineEndings(
      '${buffer.toString().trim()}\n',
      preferredLineEnding: preferredLineEndingForContent(existingContent),
    );
    outputFile.writeAsStringSync(normalized);
    return dependencyReportPath;
  }

  void _writeDependencySection(
    StringBuffer buffer, {
    required String title,
    required List<String> modules,
    required Map<String, String> packages,
  }) {
    buffer
      ..writeln('### $title')
      ..writeln();
    if (modules.isEmpty && packages.isEmpty) {
      buffer.writeln('- None');
    } else {
      if (modules.isNotEmpty) {
        buffer.writeln('- Modules: ${modules.join(', ')}');
      }
      if (packages.isNotEmpty) {
        final entries = packages.entries.map((entry) => '${entry.key} (${entry.value})').join(', ');
        buffer.writeln('- Packages: $entries');
      }
    }
    buffer.writeln();
  }

  Map<String, dynamic> _readYaml(File file) {
    final content = file.readAsStringSync();
    final node = loadYamlNode(content, sourceUrl: file.uri);
    final includeStack = <String>{file.path};
    final data = _convertYamlNode(node, file, includeStack);
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map(
        (dynamic key, dynamic value) => MapEntry(key.toString(), value),
      );
    }
    throw CommandError('Invalid YAML format in ${file.path}');
  }

  dynamic _convertYamlNode(
    YamlNode node,
    File currentFile,
    Set<String> includeStack,
  ) {
    if (node is YamlScalar) {
      return node.value;
    }

    if (node is YamlMap) {
      final result = <String, dynamic>{};
      node.nodes.forEach((dynamic keyNode, YamlNode valueNode) {
        final key = _convertYamlNode(
          keyNode as YamlNode,
          currentFile,
          includeStack,
        )?.toString();
        if (key == null || key.isEmpty) {
          return;
        }
        result[key] = _convertYamlNode(valueNode, currentFile, includeStack);
      });
      return _maybeConvertIncludeDirective(result, currentFile, includeStack);
    }

    if (node is YamlList) {
      return node.nodes.map((child) => _convertYamlNode(child, currentFile, includeStack)).toList();
    }

    return node.value;
  }

  dynamic _maybeConvertIncludeDirective(
    Map<String, dynamic> map,
    File currentFile,
    Set<String> includeStack,
  ) {
    if (!_isIncludeDirective(map)) {
      return map;
    }

    final pathValue = map['include'];
    final source = pathValue?.toString().trim();
    if (source == null || source.isEmpty) {
      throw CommandError('Empty include path in ${currentFile.path}');
    }

    final raw = _parseRawFlag(map['raw']);
    final includeFile = _resolveIncludeFile(source, currentFile.parent);
    if (!includeStack.add(includeFile.path)) {
      throw CommandError(
        'Circular include detected for $source in ${currentFile.path}',
      );
    }
    try {
      if (raw) {
        return YamlIncludeNode(
          source: source,
          absolutePath: includeFile.path,
          type: YamlIncludeType.raw,
          value: includeFile.readAsStringSync(),
        );
      }
      final content = includeFile.readAsStringSync();
      final node = loadYamlNode(content, sourceUrl: includeFile.uri);
      final value = _convertYamlNode(node, includeFile, includeStack);
      return YamlIncludeNode(
        source: source,
        absolutePath: includeFile.path,
        type: YamlIncludeType.yaml,
        value: value,
      );
    } finally {
      includeStack.remove(includeFile.path);
    }
  }

  bool _isIncludeDirective(Map<String, dynamic> map) {
    if (!map.containsKey('include')) {
      return false;
    }
    final allowedKeys = {'include', 'raw'};
    return map.keys.every(allowedKeys.contains);
  }

  bool _parseRawFlag(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value == null) {
      return false;
    }
    final normalized = value.toString().toLowerCase().trim();
    return normalized == 'true' || normalized == 'yes';
  }

  File _resolveIncludeFile(String includePath, Directory relativeTo) {
    final cleaned = includePath.trim();
    final candidates = <String>[];
    if (p.isAbsolute(cleaned)) {
      candidates.add(p.normalize(cleaned));
    } else {
      candidates
        ..add(p.normalize(p.join(relativeTo.path, cleaned)))
        ..add(p.normalize(p.join(_root.path, cleaned)));
    }

    for (final candidate in candidates) {
      final file = File(candidate);
      if (file.existsSync()) {
        return file;
      }
    }

    throw CommandError(
      'Include target $includePath not found for ${relativeTo.path}',
    );
  }

  Map<String, dynamic> _normalizeMap(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      result[entry.key] = _normalizeValue(entry.value);
    }
    return result;
  }

  dynamic _normalizeValue(dynamic value) {
    if (value is YamlIncludeNode) {
      return _normalizeValue(value.value);
    }
    if (value is Map) {
      final normalizedEntries = <String, dynamic>{};
      value.forEach((key, dynamic entryValue) {
        normalizedEntries[key.toString()] = _normalizeValue(entryValue);
      });
      return normalizedEntries;
    }
    if (value is List) {
      return value.map(_normalizeValue).toList();
    }
    return value;
  }

  void _ensureDirectory(String filePath) {
    final directory = Directory(p.dirname(filePath));
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
  }

  List<String> _moduleYamlOrder(Iterable<String> additionalKeys) {
    const baseOrder = <String>[
      'name',
      'modules',
      'dev_modules',
      'dependencies',
      'dev_dependencies',
      'build',
    ];
    final order = <String>[...baseOrder];
    final seen = order.toSet();
    for (final key in additionalKeys) {
      if (key.isEmpty) continue;
      if (seen.add(key)) {
        order.add(key);
      }
    }
    return order;
  }
}

class _ModuleProcessResult {
  _ModuleProcessResult({
    required this.snapshot,
    required this.changed,
    required this.previousContent,
    required this.hadExistingPubspec,
  });

  final ModuleDependencySnapshot snapshot;
  final bool changed;
  final String? previousContent;
  final bool hadExistingPubspec;
}

class _BuildFileResult {
  const _BuildFileResult({
    required this.changed,
    this.previousContent,
    this.hadExistingBuild = false,
    this.manual = false,
  });

  final bool changed;
  final String? previousContent;
  final bool hadExistingBuild;
  final bool manual;
}

class _ModulePubspecData {
  _ModulePubspecData({
    required this.name,
    required this.directory,
    required this.pubspec,
    this.buildConfig,
  });

  final String name;
  final Directory directory;
  final Map<String, dynamic> pubspec;
  final dynamic buildConfig;
}

class _DependencyBreakdown {
  const _DependencyBreakdown({
    this.modules = const <String>[],
    this.packages = const <String>[],
  });

  final List<String> modules;
  final List<String> packages;
}

class _WorkspaceConfigResult {
  const _WorkspaceConfigResult({
    required this.changed,
    required this.path,
  });

  final bool changed;
  final String? path;
}
