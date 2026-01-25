import 'package:scripts/src/features/build_engine/domain/models/module_descriptor.dart';
import 'package:scripts/src/features/build_engine/features/codegen/domain/models/smart_build_options.dart';

typedef SmartBuildRunner = Future<int> Function(SmartBuildOptions options);

class GenBuildContext {
  GenBuildContext({required this.filters});

  final Iterable<String> filters;
  List<ModuleDescriptor> modules = const [];
  int exitCode = 0;
}

class GenCleanContext {
  GenCleanContext({
    required this.workerOption,
  });

  final String workerOption;
  List<ModuleDescriptor> modules = const [];
  int workerCount = 1;
  int exitCode = 0;
}

class GenWatchContext {
  GenWatchContext({
    required this.filters,
    required this.preBuild,
  });

  final Iterable<String> filters;
  final bool preBuild;
  List<ModuleDescriptor> modules = const [];
  int exitCode = 0;
}
