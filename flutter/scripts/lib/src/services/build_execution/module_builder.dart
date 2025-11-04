part of 'package:scripts/src/services/build_execution_service.dart';

bool canBuildModuleInternal(BuildState state, String moduleName) {
  Logger.debug('Checking if $moduleName can be built...');

  final dependencies = state.moduleDependencies[moduleName] ?? <String>{};

  if (dependencies.isEmpty) {
    Logger.debug('   $moduleName has no dependencies, can build');
    return true;
  }

  for (final dep in dependencies) {
    if (state.moduleBuildStatus[dep] != BuildStatus.completed) {
      Logger.debug(
        '   $moduleName waiting for $dep (status: ${state.moduleBuildStatus[dep]})',
      );
      return false;
    }
  }

  Logger.debug('   $moduleName all dependencies satisfied, can build');
  return true;
}

Future<Map<String, dynamic>> buildModuleInternal(
  BuildState state,
  String moduleName,
) async {
  final modulePath = state.modulePaths[moduleName]!;
  final logFile = '${state.buildLogsDir}/build_$moduleName.log';

  Logger.building('Building $moduleName ($modulePath)...');
  state.moduleBuildStatus[moduleName] = BuildStatus.building;

  if (state.dryRun) {
    Logger.info('[DRY RUN] Would build: $moduleName');
    state.moduleBuildStatus[moduleName] = BuildStatus.completed;
    return {'success': true, 'moduleName': moduleName};
  }

  final filters = [
    '--build-filter=lib/**',
    '--build-filter=assets/**',
  ];

  final buildArgs = [
    'run',
    'build_runner',
    'build',
    '-d',
    ...filters,
  ];

  final logSink = File(logFile).openWrite()
    ..writeln('=== Build started at ${DateTime.now().toIso8601String()} ===')
    ..writeln('Module: $moduleName')
    ..writeln('Path: $modulePath')
    ..writeln('Command: dart ${buildArgs.join(' ')}')
    ..writeln('===================================\n');

  final buildProcess = await startDartCommand(
    buildArgs,
    workingDirectory: modulePath,
  );

  state.modulePids[moduleName] = buildProcess;
  state.currentlyBuilding.add(moduleName);

  buildProcess.stdout.transform(utf8.decoder).listen(logSink.write);
  buildProcess.stderr.transform(utf8.decoder).listen(logSink.write);

  final exitCode = await buildProcess.exitCode;

  logSink.writeln(
    '\n=== Build finished at ${DateTime.now().toIso8601String()} ===',
  );
  await logSink.close();

  state.modulePids.remove(moduleName);
  state.currentlyBuilding.remove(moduleName);

  if (exitCode == 0) {
    state.moduleBuildStatus[moduleName] = BuildStatus.completed;
    Logger.success('✅ $moduleName build completed');
    return {'success': true, 'moduleName': moduleName};
  } else {
    state.moduleBuildStatus[moduleName] = BuildStatus.failed;
    Logger.error('❌ $moduleName build failed (check $logFile)');

    if (state.verbose) {
      try {
        final logContent = await File(logFile).readAsString();
        final lines = logContent.split('\n');
        final lastLines = lines.skip(lines.length - 6).take(5);
        Logger.error('Last lines from build log:');
        for (final line in lastLines) {
          if (line.trim().isNotEmpty) {
            Logger.error('   $line');
          }
        }
      } on Object catch (e) {
        Logger.debug('Error reading log file: $e');
      }
    }

    return {'success': false, 'moduleName': moduleName};
  }
}
