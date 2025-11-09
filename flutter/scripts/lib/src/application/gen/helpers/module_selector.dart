import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/domain/models/module_descriptor.dart';
import 'package:scripts/src/domain/ports/module_discovery_port.dart';

class ModuleSelector {
  const ModuleSelector(this._moduleDiscovery);

  final ModuleDiscoveryPort _moduleDiscovery;
  static const _featureAliasSuffix = '_feature';
  static const _featureModuleSuffixes = <String>[
    'data',
    'domain',
    'presentation',
    'data_shared',
    'presentation_shared',
  ];

  Future<List<ModuleDescriptor>> selectForBuild(
    Iterable<String> filters,
  ) async {
    final modules = await _moduleDiscovery.discover(
      includeNonBuildRunner: true,
    );
    if (modules.isEmpty) {
      Console.error('No modules discovered. Are you in the repository root?');
      return const [];
    }

    final targets = <ModuleDescriptor>[];
    if (filters.isEmpty) {
      targets.addAll(modules.where((module) => module.hasBuildRunner));
      Console.info('Building all modules with build_runner...');
    } else {
      Console.info('Building selected modules: ${filters.join(', ')}');
      final seenNames = <String>{};
      for (final filter in filters) {
        if (_tryAddFeatureModules(
          modules: modules,
          filter: filter,
          targets: targets,
          seenNames: seenNames,
          enforceBuildRunner: true,
        )) {
          continue;
        }

        final module = _moduleDiscovery.find(modules, filter);
        if (module == null) {
          Console.warning(
            "Module '$filter' not found by name or path, skipping...",
          );
          continue;
        }
        if (!module.hasBuildRunner) {
          Console.warning(
            "Module '${module.name}' does not depend on build_runner, skipping...",
          );
          continue;
        }
        if (seenNames.add(module.name)) {
          targets.add(module);
        }
      }
    }
    return targets;
  }

  Future<List<ModuleDescriptor>> selectForClean() async {
    return _moduleDiscovery.discover(includeNonBuildRunner: false);
  }

  Future<List<ModuleDescriptor>> selectForWatch(
    Iterable<String> filters,
  ) async {
    final modules = await _moduleDiscovery.discover(
      includeNonBuildRunner: false,
    );
    if (modules.isEmpty) {
      Console.warning('No modules with build_runner were found.');
      return const [];
    }
    if (filters.isEmpty) {
      return modules;
    }
    final targets = <ModuleDescriptor>[];
    final seenNames = <String>{};
    for (final value in filters) {
      if (_tryAddFeatureModules(
        modules: modules,
        filter: value,
        targets: targets,
        seenNames: seenNames,
        enforceBuildRunner: false,
      )) {
        continue;
      }

      final module = _moduleDiscovery.find(modules, value);
      if (module == null) {
        Console.warning("Module '$value' not found, skipping...");
        continue;
      }
      if (seenNames.add(module.name)) {
        targets.add(module);
      }
    }
    return targets;
  }

  bool _tryAddFeatureModules({
    required List<ModuleDescriptor> modules,
    required String filter,
    required List<ModuleDescriptor> targets,
    required Set<String> seenNames,
    required bool enforceBuildRunner,
  }) {
    if (!filter.endsWith(_featureAliasSuffix)) {
      return false;
    }

    final base = filter.substring(
      0,
      filter.length - _featureAliasSuffix.length,
    );
    if (base.isEmpty) {
      Console.warning(
        "Feature alias '$filter' is invalid, skipping...",
      );
      return true;
    }

    final matched = <String>[];
    for (final suffix in _featureModuleSuffixes) {
      final name = '${base}_$suffix';
      final module = _findByName(modules, name);
      if (module == null) {
        continue;
      }
      if (enforceBuildRunner && !module.hasBuildRunner) {
        Console.warning(
          "Module '${module.name}' does not depend on build_runner, skipping...",
        );
        continue;
      }
      if (seenNames.add(module.name)) {
        targets.add(module);
        matched.add(module.name);
      }
    }

    if (matched.isEmpty) {
      Console.warning(
        "Feature alias '$filter' did not match any modules, skipping...",
      );
    } else {
      Console.info(
        "Feature alias '$filter' matched modules: ${matched.join(', ')}",
      );
    }
    return true;
  }

  ModuleDescriptor? _findByName(
    List<ModuleDescriptor> modules,
    String name,
  ) {
    for (final module in modules) {
      if (module.name == name) {
        return module;
      }
    }
    return null;
  }
}
