import 'package:scripts/src/domain/models/module_descriptor.dart';

abstract class ModuleDiscoveryPort {
  Future<List<ModuleDescriptor>> discover({
    required bool includeNonBuildRunner,
  });

  ModuleDescriptor? find(List<ModuleDescriptor> modules, String target);
}
