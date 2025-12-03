import 'dart:collection';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/domain/models/module_config.dart';
import 'package:scripts/src/services/yaml_service.dart';
import 'package:scripts/src/utils/yaml_writer.dart';
import 'package:yaml/yaml.dart';

class ModuleConfigService {
  ModuleConfigService({
    this.workspaceConfigFile = 'workspace_modules.yaml',
    this.rootPubspecFile = 'pubspec.yaml',
    this.lockFilePath = 'build_info/modules_lock.yaml',
    this.dependencyReportPath = 'build_info/dependencies.md',
  });

  final String workspaceConfigFile;
  final String rootPubspecFile;
  final String lockFilePath;
  final String dependencyReportPath;
  final Directory _root = Directory.current;

  Future<ModuleSyncSummary> syncModules({
    required ModuleSyncOptions options,
  }) async {
    final versions = _loadWorkspaceVersions();
    final workspaceEntries = await _loadWorkspaceEntries();
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

    var filtered = _filterModules(modules, options.targets, failures);
    filtered = _filterModulesByPackages(filtered, options.packageFilters);

    final changed = <String>[];
    final unchanged = <String>[];
    final formatted = <String>[];
    final snapshots = <ModuleDependencySnapshot>[];

    for (final module in filtered) {
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
        final result = await _processModule(
          module: module,
          versions: versions,
          checkOnly: options.checkOnly,
        );
        snapshots.add(result.snapshot);
        if (result.changed) {
          changed.add(module.name);
        } else {
          unchanged.add(module.name);
        }
      } on CommandError catch (error) {
        failures[module.name] = error.message;
      } on Object catch (error) {
        failures[module.name] = 'Unexpected error: $error';
      }
    }

    final lockPath = options.generateLockFile
        ? _writeLockFile(snapshots, versions.dartSdk)
        : null;
    final reportPath = options.generateReport
        ? _writeDependencyReport(snapshots)
        : null;

    return ModuleSyncSummary(
      changed: changed,
      unchanged: unchanged,
      formatted: formatted,
      failures: failures,
      lockFilePath: lockPath,
      reportFilePath: reportPath,
      checkMode: options.checkOnly,
    );
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
        '`dart_sdk` missing from workspace_modules.yaml',
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

    return ModuleSpec(
      name: name,
      directory: directory,
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
    if (value == null) return <String>[];
    if (value is List) {
      final result = <String>[];
      final seen = <String>{};
      for (final item in value) {
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
    final cleanedTargets = targets
        .map((target) => target.trim())
        .where((target) => target.isNotEmpty)
        .toList();
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
    final cleaned = packageFilters
        .map((pkg) => pkg.trim())
        .where((pkg) => pkg.isNotEmpty)
        .toSet();
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

    return normalizedRelative == normalizedTarget ||
        relative == target ||
        p.basename(relative) == target;
  }

  List<String> _unknownPackages(
    ModuleSpec module,
    WorkspaceModuleVersions versions,
  ) {
    final unknown = <String>[];
    final seen = <String>{};
    void collect(List<String> packages) {
      for (final package in packages) {
        if (!_isFlutterSdkPackage(package) &&
            versions.versionFor(package) == null) {
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
    final sortedDevDependencies = List<String>.from(module.devDependencies)
      ..sort();

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
    };

    final writer = const YamlWriter(
      preferredOrder: [
        'name',
        'modules',
        'dev_modules',
        'dependencies',
        'dev_dependencies',
      ],
    );
    final content = '${writer.convert(data)}\n';
    final existing = file.existsSync() ? file.readAsStringSync() : '';
    if (existing.trimRight() == content.trimRight()) {
      return false;
    }
    file.writeAsStringSync(content);
    return true;
  }

  Future<_ModuleProcessResult> _processModule({
    required ModuleSpec module,
    required WorkspaceModuleVersions versions,
    required bool checkOnly,
  }) async {
    final pubspecFile = module.pubspecFile;
    if (!pubspecFile.existsSync()) {
      final relative = p.relative(module.directory.path, from: _root.path);
      throw CommandError('pubspec.yaml not found for $relative');
    }

    final pubspec = await readPubspec(pubspecFile.path) ?? <String, dynamic>{};
    final updated = Map<String, dynamic>.from(pubspec);

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

    final writer = const YamlWriter();
    final content = '${writer.convert(_normalizeMap(updated))}\n';
    final existingContent = pubspecFile.readAsStringSync();
    final normalizedExisting = existingContent.trimRight();
    final normalizedExpected = content.trimRight();
    final changed = normalizedExisting != normalizedExpected;

    if (!checkOnly && changed) {
      pubspecFile.writeAsStringSync(content);
    }

    final snapshot = _buildSnapshot(module, versions);
    return _ModuleProcessResult(snapshot: snapshot, changed: changed);
  }

  Map<String, dynamic> _buildDependencyMap({
    required List<String> moduleDependencies,
    required List<String> packageDependencies,
    required WorkspaceModuleVersions versions,
  }) {
    final map = LinkedHashMap<String, dynamic>();
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
    final map = LinkedHashMap<String, String>();
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
    return packageName == 'flutter' || packageName == 'flutter_test';
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

    final writer = const YamlWriter(
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
    File(outputPath).writeAsStringSync(content);
    return lockFilePath;
  }

  String? _writeDependencyReport(List<ModuleDependencySnapshot> snapshots) {
    final buffer = StringBuffer()
      ..writeln('# Module dependencies')
      ..writeln();

    if (snapshots.isEmpty) {
      buffer.writeln('No modules processed.');
    } else {
      final sorted = List<ModuleDependencySnapshot>.from(snapshots)
        ..sort((a, b) => a.name.compareTo(b.name));
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
    File(outputPath).writeAsStringSync('${buffer.toString().trim()}\n');
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
        final entries = packages.entries
            .map((entry) => '${entry.key} (${entry.value})')
            .join(', ');
        buffer.writeln('- Packages: $entries');
      }
    }
    buffer.writeln();
  }

  Map<String, dynamic> _readYaml(File file) {
    final content = file.readAsStringSync();
    final data = loadYaml(content);
    if (data is YamlMap) {
      return _convertYamlMap(data);
    }
    if (data is Map) {
      return data.map(
        (key, dynamic value) =>
            MapEntry(key.toString(), _convertYamlValue(value)),
      );
    }
    throw CommandError('Invalid YAML format in ${file.path}');
  }

  Map<String, dynamic> _convertYamlMap(YamlMap map) {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      result[entry.key.toString()] = _convertYamlValue(entry.value);
    }
    return result;
  }

  dynamic _convertYamlValue(dynamic value) {
    if (value is YamlMap) {
      return _convertYamlMap(value);
    }
    if (value is Map) {
      return value.map(
        (key, dynamic entryValue) =>
            MapEntry(key.toString(), _convertYamlValue(entryValue)),
      );
    }
    if (value is YamlList) {
      return value.map(_convertYamlValue).toList();
    }
    if (value is List) {
      return value.map(_convertYamlValue).toList();
    }
    return value;
  }

  Map<String, dynamic> _normalizeMap(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      result[entry.key] = _normalizeValue(entry.value);
    }
    return result;
  }

  dynamic _normalizeValue(dynamic value) {
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
}

class _ModuleProcessResult {
  _ModuleProcessResult({
    required this.snapshot,
    required this.changed,
  });

  final ModuleDependencySnapshot snapshot;
  final bool changed;
}
