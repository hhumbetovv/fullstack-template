import 'package:get_it/get_it.dart';

import 'package:scripts/src/application/build/build_executor.dart';
import 'package:scripts/src/application/gen/gen_executor.dart';
import 'package:scripts/src/application/links/links_executor.dart';
import 'package:scripts/src/application/locale/locale_executor.dart';
import 'package:scripts/src/application/module_graph/module_graph_executor.dart';
import 'package:scripts/src/application/module_graph/workflows/build_plan_builder.dart';
import 'package:scripts/src/application/module_graph/workflows/dependency_analyzer.dart';
import 'package:scripts/src/application/module_graph/workflows/graph_generator.dart';
import 'package:scripts/src/application/smart_build/smart_build_executor.dart';
import 'package:scripts/src/domain/ports/build_runner_port.dart';
import 'package:scripts/src/domain/ports/module_discovery_port.dart';
import 'package:scripts/src/domain/ports/module_graph_port.dart';
import 'package:scripts/src/infrastructure/build/android_builder.dart';
import 'package:scripts/src/infrastructure/build/ios_builder.dart';
import 'package:scripts/src/infrastructure/build/keystore_manager.dart';
import 'package:scripts/src/infrastructure/build_runner/build_runner_service.dart';
import 'package:scripts/src/infrastructure/links/link_creator.dart';
import 'package:scripts/src/infrastructure/module_graph/module_graph_service.dart';
import 'package:scripts/src/infrastructure/workspace/workspace_discovery_service.dart';
import 'package:scripts/src/services/environment_service.dart';

final GetIt _locator = GetIt.instance;
bool _configured = false;

void configureDependencies() {
  if (_configured) {
    return;
  }
  _configured = true;

  _locator
    ..registerLazySingleton<ModuleDiscoveryPort>(
      WorkspaceDiscoveryService.new,
    )
    ..registerLazySingleton<BuildRunnerPort>(BuildRunnerService.new)
    ..registerLazySingleton<EnvironmentService>(EnvironmentService.new)
    ..registerLazySingleton<DependencyAnalyzer>(DependencyAnalyzer.new)
    ..registerLazySingleton<BuildPlanBuilder>(BuildPlanBuilder.new)
    ..registerLazySingleton<GraphGenerator>(GraphGenerator.new)
    ..registerLazySingleton<ModuleGraphPort>(
      () => ModuleGraphService(
        dependencyAnalyzer: _locator.get<DependencyAnalyzer>(),
        buildPlanBuilder: _locator.get<BuildPlanBuilder>(),
        graphGenerator: _locator.get<GraphGenerator>(),
      ),
    )
    ..registerLazySingleton<AndroidBuildService>(AndroidBuildService.new)
    ..registerLazySingleton<IosBuildService>(IosBuildService.new)
    ..registerLazySingleton<AndroidKeystoreManager>(AndroidKeystoreManager.new)
    ..registerLazySingleton<LinkCreator>(LinkCreator.new)
    ..registerLazySingleton<LocaleExecutor>(LocaleExecutor.new)
    ..registerLazySingleton<BuildExecutor>(
      () => BuildExecutor(
        androidBuildService: _locator.get<AndroidBuildService>(),
        iosBuildService: _locator.get<IosBuildService>(),
        keystoreManager: _locator.get<AndroidKeystoreManager>(),
      ),
    )
    ..registerLazySingleton<LinksExecutor>(
      () => LinksExecutor(linkCreator: _locator.get<LinkCreator>()),
    )
    ..registerLazySingleton<SmartBuildExecutor>(
      () => SmartBuildExecutor(
        moduleGraphPort: _locator.get<ModuleGraphPort>(),
        environmentService: _locator.get<EnvironmentService>(),
      ),
    )
    ..registerLazySingleton<ModuleGraphExecutor>(
      () => ModuleGraphExecutor(
        moduleGraphPort: _locator.get<ModuleGraphPort>(),
        environmentService: _locator.get<EnvironmentService>(),
      ),
    )
    ..registerFactory<GenExecutor>(
      () => GenExecutor(
        moduleDiscovery: _locator.get<ModuleDiscoveryPort>(),
        buildRunner: _locator.get<BuildRunnerPort>(),
        smartBuildRunner: (options) =>
            _locator.get<SmartBuildExecutor>().run(options),
      ),
    );
}

T getDependency<T extends Object>() => _locator.get<T>();
