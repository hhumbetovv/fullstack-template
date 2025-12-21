import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:scripts/src/features/build_engine/domain/adapters/workspace_discovery_adapter.dart';
import 'package:scripts/src/features/build_engine/domain/ports/module_discovery_port.dart';
import 'package:scripts/src/features/build_engine/domain/ports/module_graph_port.dart';
import 'package:scripts/src/features/build_engine/engine/services/environment_service.dart';
import 'package:scripts/src/features/build_engine/engine/services/workspace_state_loader.dart';
import 'package:scripts/src/features/build_engine/features/codegen/commands/build/build_executor.dart';
import 'package:scripts/src/features/build_engine/features/codegen/commands/gen_build/gen_executor.dart';
import 'package:scripts/src/features/build_engine/features/codegen/commands/smart_build/smart_build_executor.dart';
import 'package:scripts/src/features/build_engine/features/codegen/domain/adapters/build/android_builder.dart';
import 'package:scripts/src/features/build_engine/features/codegen/domain/adapters/build/ios_builder.dart';
import 'package:scripts/src/features/build_engine/features/codegen/domain/adapters/build/keystore_manager.dart';
import 'package:scripts/src/features/build_engine/features/codegen/domain/adapters/build_runner/build_runner_service.dart';
import 'package:scripts/src/features/build_engine/features/codegen/domain/ports/build_runner_port.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/build_execution/build_execution_service.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/build_execution/build_scheduler.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/build_execution/log_manager.dart';
import 'package:scripts/src/features/build_engine/features/codegen/engine/services/build_execution/module_builder.dart';
import 'package:scripts/src/features/build_engine/features/module_graph/commands/module_graph/module_graph_executor.dart';
import 'package:scripts/src/features/build_engine/features/module_graph/engine/services/build_plan_builder.dart';
import 'package:scripts/src/features/build_engine/features/module_graph/engine/services/dependency_analyzer.dart';
import 'package:scripts/src/features/build_engine/features/module_graph/engine/services/graph_generator.dart';
import 'package:scripts/src/features/build_engine/features/module_graph/engine/services/module_graph_service.dart';
import 'package:scripts/src/features/links/commands/links_executor.dart';
import 'package:scripts/src/features/links/domain/adapters/link_creator.dart';
import 'package:scripts/src/features/locale/commands/locale_executor.dart';
import 'package:scripts/src/features/scaffolding/domain/adapters/module_config_service.dart';
import 'package:scripts/src/features/scaffolding/features/create_module/commands/create_module/module_create_executor.dart';
import 'package:scripts/src/features/scaffolding/features/pub_sync/commands/pub_sync/pub_sync_executor.dart';

final GetIt _locator = GetIt.instance;
bool _configured = false;

void configureDependencies() {
  if (_configured) {
    return;
  }
  _configured = true;

  _locator
    ..registerLazySingleton<ModuleDiscoveryPort>(
      WorkspaceDiscoveryAdapter.new,
    )
    ..registerLazySingleton<BuildRunnerPort>(BuildRunnerService.new)
    ..registerLazySingleton<EnvironmentService>(EnvironmentService.new)
    ..registerLazySingleton<DependencyAnalyzer>(DependencyAnalyzer.new)
    ..registerLazySingleton<BuildPlanBuilder>(BuildPlanBuilder.new)
    ..registerLazySingleton<GraphGenerator>(GraphGenerator.new)
    ..registerLazySingleton<WorkspaceStateLoader>(WorkspaceStateLoader.new)
    ..registerLazySingleton<BuildLogManager>(BuildLogManager.new)
    ..registerLazySingleton<ModuleBuildRunner>(ModuleBuildRunner.new)
    ..registerLazySingleton<BuildScheduler>(
      () => BuildScheduler(
        logManager: _locator.get<BuildLogManager>(),
        moduleBuilder: _locator.get<ModuleBuildRunner>(),
      ),
    )
    ..registerLazySingleton<BuildExecutionService>(
      () => BuildExecutionService(
        scheduler: _locator.get<BuildScheduler>(),
        logManager: _locator.get<BuildLogManager>(),
        moduleBuilder: _locator.get<ModuleBuildRunner>(),
      ),
    )
    ..registerLazySingleton<ModuleGraphPort>(
      () => ModuleGraphService(
        dependencyAnalyzer: _locator.get<DependencyAnalyzer>(),
        buildPlanBuilder: _locator.get<BuildPlanBuilder>(),
        graphGenerator: _locator.get<GraphGenerator>(),
        workspaceStateLoader: _locator.get<WorkspaceStateLoader>(),
      ),
    )
    ..registerLazySingleton<AndroidBuildService>(AndroidBuildService.new)
    ..registerLazySingleton<IosBuildService>(IosBuildService.new)
    ..registerLazySingleton<AndroidKeystoreManager>(AndroidKeystoreManager.new)
    ..registerLazySingleton<LinkCreator>(LinkCreator.new)
    ..registerLazySingleton<ModuleCreateExecutor>(
      () => ModuleCreateExecutor(
        moduleConfigService: _locator.get<ModuleConfigService>(),
        workspaceRoot: Directory.current.path,
      ),
    )
    ..registerLazySingleton<ModuleConfigService>(ModuleConfigService.new)
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
    ..registerLazySingleton<PubSyncExecutor>(
      () => PubSyncExecutor(service: _locator.get<ModuleConfigService>()),
    )
    ..registerLazySingleton<SmartBuildExecutor>(
      () => SmartBuildExecutor(
        moduleGraphPort: _locator.get<ModuleGraphPort>(),
        environmentService: _locator.get<EnvironmentService>(),
        buildExecutionService: _locator.get<BuildExecutionService>(),
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
