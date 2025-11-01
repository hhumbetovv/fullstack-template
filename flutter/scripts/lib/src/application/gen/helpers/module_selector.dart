import 'package:scripts/src/core/logging/console.dart';
import 'package:scripts/src/domain/models/module_descriptor.dart';
import 'package:scripts/src/domain/ports/module_discovery_port.dart';

class ModuleSelector {
  const ModuleSelector(this._moduleDiscovery);

  final ModuleDiscoveryPort _moduleDiscovery;

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
      for (final filter in filters) {
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
        targets.add(module);
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
    for (final value in filters) {
      final module = _moduleDiscovery.find(modules, value);
      if (module == null) {
        Console.warning("Module '$value' not found, skipping...");
        continue;
      }
      targets.add(module);
    }
    return targets;
  }
}
