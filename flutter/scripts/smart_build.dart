#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

enum BuildStatus { pending, building, completed, failed }

// Global state
class BuildState {
  Map<String, String> modulePaths = {}; // module_name -> path
  Map<String, Set<String>> moduleDependencies = {}; // module_name -> dependencies
  Map<String, BuildStatus> moduleBuildStatus = {}; // module_name -> status
  Map<String, Process> modulePids = {}; // module_name -> process
  Map<String, int> moduleBuildLevel = {}; // module_name -> build_level
  List<String> buildOrder = []; // Final build order
  Set<String> currentlyBuilding = <String>{};
  int maxParallelBuilds = 8;
  bool verbose = false;
  bool dryRun = false;
  String buildLogsDir = 'build_logs';
  String? targetModule;
}

final BuildState state = BuildState();

class Colors {
  static const String red = '\x1b[0;31m';
  static const String green = '\x1b[0;32m';
  static const String yellow = '\x1b[1;33m';
  static const String blue = '\x1b[0;34m';
  static const String purple = '\x1b[0;35m';
  static const String cyan = '\x1b[0;36m';
  static const String gray = '\x1b[0;90m';
  static const String nc = '\x1b[0m'; // No Color
}

// ignore: avoid_print
void log(dynamic data) => print(data);

// Logging functions
sealed class Logger {
  static void info(String message) {
    log('${Colors.blue}ℹ️  $message${Colors.nc}');
  }

  static void success(String message) {
    log('${Colors.green}✅ $message${Colors.nc}');
  }

  static void warning(String message) {
    log('${Colors.yellow}⚠️  $message${Colors.nc}');
  }

  static void error(String message) {
    log('${Colors.red}❌ $message${Colors.nc}');
  }

  static void building(String message) {
    log('${Colors.purple}🔨 $message${Colors.nc}');
  }

  static void debug(String message) {
    if (state.verbose) {
      log('${Colors.gray}🔍 DEBUG: $message${Colors.nc}');
    }
  }

  static void verbose(String message) {
    if (state.verbose) {
      log('${Colors.cyan}   → $message${Colors.nc}');
    }
  }
}

// Parse command line arguments
void parseArguments(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--verbose':
      case '-v':
        state.verbose = true;
      case '--dry-run':
        state.dryRun = true;
      case '--parallel':
      case '-p':
        if (i + 1 < args.length) {
          state.maxParallelBuilds = int.tryParse(args[++i]) ?? 4;
        }
      case '--help':
      case '-h':
        showHelp();
        exit(0);
      default:
        state.targetModule = args[i];
    }
  }
}

// Show help
void showHelp() {
  log('''
Flutter Smart Build System

Usage: dart build.dart [OPTIONS] [MODULE_NAME]

Options:
    --verbose, -v       Enable verbose debug output
    --dry-run          Show what would be built without actually building
    --parallel, -p N    Set max parallel builds (default: 4)
    --help, -h         Show this help message

Examples:
    dart build.dart                          # Build all modules
    dart build.dart --verbose               # Build all with debug output
    dart build.dart demo_presentation        # Build specific module by name
    dart build.dart --dry-run --verbose     # Show build plan without executing

Note: Module names are taken directly from pubspec.yaml files, not derived from paths.
''');
}

Future<void> validateEnvironment() async {
  Logger.debug('Validating environment...');

  // Check for dart/flutter
  try {
    await Process.run('which', ['dart']);
  } on Exception catch (_) {
    try {
      await Process.run('which', ['fvm']);
    } on Exception catch (_) {
      Logger.error("Neither 'dart' nor 'fvm' command found. Please ensure Flutter is installed.");
      exit(1);
    }
  }

  // Check if we're in a Flutter project
  final rootPubspec = File('pubspec.yaml');
  if (!rootPubspec.existsSync()) {
    Logger.error('No pubspec.yaml found in current directory. Please run from Flutter project root.');
    exit(1);
  }

  Logger.debug('Environment validation passed');
}

// Cleanup function
void cleanup() {
  Logger.warning('🛑 Interrupt received, cleaning up...');

  // Kill all running builds
  for (final entry in state.modulePids.entries) {
    try {
      Logger.debug('Killing build process for ${entry.key} (PID: ${entry.value.pid})');
      entry.value.kill();
    } on Exception catch (e) {
      Logger.debug('Error killing process for ${entry.key}: $e');
    }
  }

  Logger.info('Cleanup completed');
  exit(130);
}

class YamlContext {
  YamlContext(
    this.container,
    this.indent,
    this.key,
  );
  final dynamic container;
  final int indent;
  final String? key;
}

class YamlParser {
  static Map<String, dynamic> parse(String content) {
    final trimmedInput = content.trim();

    if (trimmedInput.startsWith('{') && trimmedInput.endsWith('}')) {
      final correctedJson = trimmedInput
          .replaceAllMapped(RegExp(r'(\w+):'), (match) => '"${match.group(1)}":')
          .replaceAll(' ', '')
          .replaceAll('"', ' ')
          .replaceAll('{ ', '{')
          .replaceAll(' }', '}')
          .replaceAll(',', ', ');

      try {
        final decoded = json.decode(correctedJson.replaceAll("'", ' '));
        if (decoded is Map<String, dynamic>) return decoded;
        return {};
      } on Exception catch (_) {}
    }

    final lines = content.split('\n');
    final result = <String, dynamic>{};
    // A map to keep track of the current object (map or list) at each indentation level.
    // The key is the indentation level, and the value is the object itself.
    final indentationMap = <int, dynamic>{-2: result};
    var lastIndentation = -2;

    for (final line in lines) {
      // Trim leading and trailing whitespace to get the actual content.
      final trimmedLine = line.trim();

      // Skip empty lines and comment lines.
      if (trimmedLine.isEmpty || trimmedLine.startsWith('#') || trimmedLine.startsWith('!')) {
        continue;
      }

      // Find the indentation level by counting leading spaces.
      final currentIndentation = line.indexOf(trimmedLine);

      // Find the parent object in the indentation map.
      // We iterate backwards from the current indentation to find the closest
      // parent with a smaller indentation.
      dynamic parent = indentationMap[lastIndentation];
      while (lastIndentation >= currentIndentation) {
        lastIndentation -= 2; // Assuming 2 spaces per indentation level
        parent = indentationMap[lastIndentation];
        if (parent != null) {
          break;
        }
      }

      // Handle list items (lines starting with a hyphen).
      if (trimmedLine.startsWith('-')) {
        // The parent must be a List, so we cast it.
        if (parent is List) {
          final value = trimmedLine.substring(1).trim();
          parent.add(value);
        } else {
          if (parent is Map && parent.isNotEmpty && parent.values.last is List) {
            final list = parent.values.last as List;
            final value = trimmedLine.substring(1).trim();
            list.add(value);
          }
        }
      } else {
        // Handle key-value pairs or nested map/list definitions.
        final parts = trimmedLine.split(':');
        final key = parts[0].trim();
        final valuePart = parts.length > 1 ? parts.sublist(1).join(':').trim() : '';

        // Check if the value is empty, indicating a nested map or list.
        if (valuePart.isEmpty) {
          final isListKey = key == 'workspace' || key == 'assets';
          final newObject = isListKey ? <dynamic>[] : <String, dynamic>{};

          if (parent is Map<String, dynamic>) {
            parent[key] = newObject;
          }

          // Update the indentation map with the new object.
          indentationMap[currentIndentation] = newObject;
          lastIndentation = currentIndentation;
        } else {
          // Simple key-value pair.
          if (parent is Map<String, dynamic>) {
            parent[key] = valuePart;
          }
        }
      }
    }

    return result;
  }
}

// Read and parse pubspec file
Future<Map<String, dynamic>?> readPubspec(String filePath) async {
  try {
    final file = File(filePath);
    if (!file.existsSync()) return null;

    final content = await file.readAsString();
    return YamlParser.parse(content);
  } on Exception catch (e) {
    Logger.debug('Error reading $filePath: $e');
    return null;
  }
}

// Get package name from pubspec
String? getPackageName(Map<String, dynamic> pubspec) {
  return pubspec['name']?.toString();
}

// Check if pubspec contains build_runner
bool hasBuildRunner(Map<String, dynamic> pubspec) {
  final dependencies = pubspec['dependencies'] as Map<String, dynamic>?;
  final devDependencies = pubspec['dev_dependencies'] as Map<String, dynamic>?;

  return (dependencies?.containsKey('build_runner') ?? false) ||
      (devDependencies?.containsKey('build_runner') ?? false);
}

// Check if module should be ignored (generators)
bool shouldIgnoreModule(String moduleName) {
  return moduleName.startsWith('gen_') || moduleName.contains('generator') || moduleName.contains('_gen');
}

Future<void> _discoverWorkspaceModules(List<dynamic> workspace) async {
  final workspacePaths = workspace.whereType<String>();

  if (workspacePaths.isEmpty) {
    Logger.warning('Workspace configuration found but no paths specified');
    return;
  }

  var discoveredCount = 0;
  final totalPaths = workspacePaths.length;

  Logger.info('Found $totalPaths workspace paths to analyze');

  for (final workspacePath in workspacePaths) {
    Logger.debug('Analyzing workspace path: $workspacePath');

    // Check pubspec directly with the workspace path
    var cleanPath = workspacePath;
    // Ensure path starts with ./ for consistency
    if (!cleanPath.startsWith('./') && !cleanPath.startsWith('/')) {
      cleanPath = './$cleanPath';
    }

    final pubspecPath = '$cleanPath/pubspec.yaml';

    Logger.debug('   Checking: $pubspecPath');

    // Read module pubspec
    final modulePubspec = await readPubspec(pubspecPath);
    if (modulePubspec == null) {
      Logger.debug('   ⏭️  Skipped (no pubspec.yaml): $workspacePath');
      continue;
    }

    // Get actual module name from pubspec
    final actualModuleName = getPackageName(modulePubspec);
    if (actualModuleName == null) {
      Logger.debug('   ⏭️  Skipped (no name in pubspec): $workspacePath');
      continue;
    }

    // Check if has build_runner
    if (!hasBuildRunner(modulePubspec)) {
      Logger.debug('   ⏭️  Skipped (no build_runner): $actualModuleName → $workspacePath');
      continue;
    }

    // Skip generator modules
    if (shouldIgnoreModule(actualModuleName)) {
      Logger.debug('   ⏭️  Skipped (generator module): $actualModuleName → $workspacePath');
      continue;
    }

    // Store module info with clean path
    state.modulePaths[actualModuleName] = cleanPath;
    state.moduleBuildStatus[actualModuleName] = BuildStatus.pending;

    Logger.verbose('✅ Module found: $actualModuleName → $cleanPath');
    discoveredCount++;
  }

  Logger.success('Discovered $discoveredCount modules with build_runner (out of $totalPaths workspace paths)');

  if (state.verbose) {
    Logger.info('📋 All discovered modules:');
    for (final entry in state.modulePaths.entries) {
      Logger.verbose('${entry.key} → ${entry.value}');
    }
  }
}

Future<void> _discoverPathDependencies(Map<String, dynamic> rootPubspec) async {
  final dependencies = rootPubspec['dependencies'] as Map<String, dynamic>?;
  final devDependencies = rootPubspec['dev_dependencies'] as Map<String, dynamic>?;

  if (dependencies == null && devDependencies == null) {
    Logger.warning('No dependencies found in root pubspec.yaml');
    return;
  }

  // Combine all dependencies
  final allDeps = <String, dynamic>{};
  if (dependencies != null) {
    dependencies.forEach((key, value) {
      allDeps[key] = value;
    });
  }
  if (devDependencies != null) {
    devDependencies.forEach((key, value) {
      allDeps[key] = value;
    });
  }

  var discoveredCount = 0;
  final totalDeps = allDeps.length;

  Logger.info('Found $totalDeps dependencies to analyze');

  for (final entry in allDeps.entries) {
    final depName = entry.key;
    final depConfig = entry.value;

    Logger.debug('Analyzing dependency: $depName');

    // Skip non-path dependencies
    if (depConfig is! Map<String, dynamic> || !depConfig.containsKey('path')) {
      Logger.debug('   ⏭️  Skipped (not a path dependency): $depName');
      continue;
    }

    final depPath = depConfig['path']?.toString();
    if (depPath == null) {
      Logger.debug('   ⏭️  Skipped (no path): $depName');
      continue;
    }

    // Clean path
    var cleanPath = depPath;
    if (!cleanPath.startsWith('./') && !cleanPath.startsWith('/')) {
      cleanPath = './$cleanPath';
    }

    final pubspecPath = '$cleanPath/pubspec.yaml';

    Logger.debug('   Checking: $pubspecPath');

    // Read module pubspec
    final modulePubspec = await readPubspec(pubspecPath);
    if (modulePubspec == null) {
      Logger.debug('   ⏭️  Skipped (no pubspec.yaml): $depPath');
      continue;
    }

    // Get actual module name from pubspec
    final actualModuleName = getPackageName(modulePubspec);
    if (actualModuleName == null) {
      Logger.debug('   ⏭️  Skipped (no name in pubspec): $depPath');
      continue;
    }

    // Check if has build_runner
    if (!hasBuildRunner(modulePubspec)) {
      Logger.debug('   ⏭️  Skipped (no build_runner): $actualModuleName → $depPath');
      continue;
    }

    // Skip generator modules
    if (shouldIgnoreModule(actualModuleName)) {
      Logger.debug('   ⏭️  Skipped (generator module): $actualModuleName → $depPath');
      continue;
    }

    // Store module info
    state.modulePaths[actualModuleName] = cleanPath;
    state.moduleBuildStatus[actualModuleName] = BuildStatus.pending;

    Logger.verbose('✅ Module found: $actualModuleName → $cleanPath');
    discoveredCount++;
  }

  Logger.success('Discovered $discoveredCount modules with build_runner (out of $totalDeps dependencies)');

  if (state.verbose) {
    Logger.info('📋 All discovered modules:');
    for (final entry in state.modulePaths.entries) {
      Logger.verbose('${entry.key} → ${entry.value}');
    }
  }
}

// Discover all modules from root pubspec
Future<void> discoverModulesFromRoot() async {
  Logger.info('🔍 Discovering modules from root pubspec.yaml...');

  // Read root pubspec
  final rootPubspec = await readPubspec('pubspec.yaml');

  if (rootPubspec == null) {
    Logger.error('Could not read root pubspec.yaml');
    exit(1);
  }

  // Check for workspace configuration first
  final workspace = rootPubspec['workspace'];

  if (workspace != null && workspace is List) {
    Logger.info('Found workspace configuration, analyzing workspace modules...');
    await _discoverWorkspaceModules(workspace);
    return;
  }

  // Fallback to legacy path dependencies approach
  Logger.info('No workspace found, checking path dependencies...');
  await _discoverPathDependencies(rootPubspec);
}

// Parse dependencies from pubspec.yaml
Future<Set<String>> parseDependencies(String pubspecPath, String moduleName) async {
  final dependencies = <String>{};

  try {
    final pubspec = await readPubspec(pubspecPath);
    if (pubspec == null) return dependencies;

    final deps = pubspec['dependencies'] as Map<String, dynamic>?;
    final devDeps = pubspec['dev_dependencies'] as Map<String, dynamic>?;

    // Helper function to process dependencies
    void processDeps(Map<String, dynamic>? depsMap) {
      if (depsMap == null) return;

      depsMap.forEach((key, value) {
        final depName = key;

        // Skip if this dependency is not in our module list
        if (!state.modulePaths.containsKey(depName)) {
          return;
        }

        // Skip generator modules
        if (shouldIgnoreModule(depName)) {
          return;
        }

        dependencies.add(depName);
        Logger.debug('   Found dependency: $moduleName → $depName');
      });
    }

    processDeps(deps);
    processDeps(devDeps);
  } on Exception catch (e) {
    Logger.error('Error parsing dependencies from $pubspecPath: $e');
  }

  return dependencies;
}

// Build dependency graph
Future<void> buildDependencyGraph() async {
  Logger.info('🕸️  Building dependency graph...');

  for (final entry in state.modulePaths.entries) {
    final moduleName = entry.key;
    final modulePath = entry.value;
    final pubspecFile = '$modulePath/pubspec.yaml';

    final dependencies = await parseDependencies(pubspecFile, moduleName);
    state.moduleDependencies[moduleName] = dependencies;

    if (dependencies.isNotEmpty) {
      Logger.info('   📦 $moduleName depends on: ${dependencies.join(', ')}');
    } else {
      Logger.verbose('   📦 $moduleName has no internal dependencies');
    }
  }

  if (state.verbose) {
    Logger.info('📊 Dependency Summary:');
    for (final entry in state.moduleDependencies.entries) {
      Logger.verbose('${entry.key}: ${entry.value.length} dependencies');
    }
  }
}

// Calculate build levels (waves)
void calculateBuildLevels() {
  Logger.info('🌊 Calculating build waves...');

  final inDegree = <String, int>{};
  final tempInDegree = <String, int>{};

  // Initialize in-degrees
  for (final moduleName in state.modulePaths.keys) {
    inDegree[moduleName] = 0;
  }

  // Calculate in-degrees
  for (final entry in state.moduleDependencies.entries) {
    for (final _ in entry.value) {
      inDegree[entry.key] = (inDegree[entry.key] ?? 0) + 1;
    }
  }

  // Copy in-degrees for manipulation
  tempInDegree.addAll(inDegree);

  // Calculate levels
  var level = 0;
  var processed = 0;
  final total = state.modulePaths.length;

  while (processed < total) {
    final waveModules = <String>[];

    // Find modules with in-degree 0
    for (final entry in tempInDegree.entries) {
      if (entry.value == 0 && !state.moduleBuildLevel.containsKey(entry.key)) {
        state.moduleBuildLevel[entry.key] = level;
        waveModules.add(entry.key);
        processed++;
      }
    }

    if (waveModules.isEmpty && processed < total) {
      Logger.error('Circular dependency detected or disconnected modules!');
      for (final entry in tempInDegree.entries) {
        if (!state.moduleBuildLevel.containsKey(entry.key)) {
          Logger.error('   Stuck module: ${entry.key} (in-degree: ${entry.value})');
        }
      }
      throw Exception('Circular dependency detected');
    }

    // Log wave
    if (waveModules.isNotEmpty) {
      Logger.info('   🌊 Wave $level: ${waveModules.join(' ')}');
    }

    // Update in-degrees for next level
    for (final module in waveModules) {
      for (final entry in state.moduleDependencies.entries) {
        if (entry.value.contains(module)) {
          tempInDegree[entry.key] = (tempInDegree[entry.key] ?? 0) - 1;
        }
      }
    }

    level++;
  }

  Logger.success('Build waves calculated: $level waves total');
}

// Generate enhanced Mermaid graph
Future<void> generateMermaidGraph() async {
  Logger.info('📊 Generating dependency graph (build_graph.md)...');

  final content = StringBuffer()
    ..writeln('# Flutter Module Dependency Graph')
    ..writeln('')
    ..writeln('## Visual Representation')
    ..writeln('')
    ..writeln('```mermaid')
    ..writeln('graph TD');

  // Add nodes with styling and build levels
  for (final entry in state.modulePaths.entries) {
    final moduleName = entry.key;
    final level = state.moduleBuildLevel[moduleName] ?? 0;
    content.writeln('    $moduleName["$moduleName\n🌊 Wave $level"]');

    // Style based on module naming patterns
    if (moduleName.contains('_presentation') || moduleName.endsWith('_ui')) {
      content.writeln('    $moduleName:::presentation');
    } else if (moduleName.contains('_domain') || moduleName.contains('_business')) {
      content.writeln('    $moduleName:::domain');
    } else if (moduleName.contains('_data') || moduleName.contains('_repository')) {
      content.writeln('    $moduleName:::data');
    } else if (moduleName.startsWith('ui_') || moduleName.contains('_ui')) {
      content.writeln('    $moduleName:::ui');
    } else if (moduleName.startsWith('common_') || moduleName.contains('_common')) {
      content.writeln('    $moduleName:::common');
    } else if (moduleName.startsWith('core_') || moduleName.contains('_core')) {
      content.writeln('    $moduleName:::core');
    }
  }

  content.writeln('');

  // Add dependencies
  for (final entry in state.moduleDependencies.entries) {
    for (final dep in entry.value) {
      content.writeln('    $dep --> ${entry.key}');
    }
  }

  // Add styling
  content
    ..writeln('')
    ..writeln('    classDef presentation fill:#e1f5fe,stroke:#0277bd,stroke-width:2px,color:#000000')
    ..writeln('    classDef domain fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000000')
    ..writeln('    classDef data fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px,color:#000000')
    ..writeln('    classDef ui fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000000')
    ..writeln('    classDef common fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000000')
    ..writeln('    classDef core fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000000')
    ..writeln('```')
    ..writeln('')
    ..writeln('## Build Statistics')
    ..writeln('');

  // Add statistics
  final totalModules = state.modulePaths.length;
  var totalDependencies = 0;
  for (final deps in state.moduleDependencies.values) {
    totalDependencies += deps.length;
  }

  content
    ..writeln('- **Total Modules**: $totalModules')
    ..writeln('- **Total Dependencies**: $totalDependencies')
    ..writeln(
      '- **Average Dependencies**: ${totalModules > 0 ? (totalDependencies / totalModules).toStringAsFixed(2) : 0}',
    )
    ..writeln('- **Max Parallel Builds**: ${state.maxParallelBuilds}')
    ..writeln('')
    ..writeln('## Build Waves')
    ..writeln('')
    ..writeln('The modules will be built in the following waves:')
    ..writeln('');

  // Group modules by level
  var maxLevel = 0;
  for (final level in state.moduleBuildLevel.values) {
    if (level > maxLevel) {
      maxLevel = level;
    }
  }

  for (var level = 0; level <= maxLevel; level++) {
    content
      ..writeln('')
      ..writeln('### Wave $level')
      ..writeln('');

    for (final entry in state.moduleBuildLevel.entries) {
      if (entry.value == level) {
        final deps = state.moduleDependencies[entry.key] ?? <String>{};
        if (deps.isNotEmpty) {
          content.writeln('- **${entry.key}** → depends on: ${deps.join(', ')}');
        } else {
          content.writeln('- **${entry.key}** → no dependencies');
        }
      }
    }
  }

  await File('build_graph.md').writeAsString(content.toString());
  Logger.success('Dependency graph saved to build_graph.md');
}

// Topological sort to determine build order
void topologicalSort() {
  Logger.info('🔄 Calculating optimal build order...');

  final inDegree = <String, int>{};
  final adjList = <String, Set<String>>{};

  // Initialize
  for (final moduleName in state.modulePaths.keys) {
    inDegree[moduleName] = 0;
    adjList[moduleName] = <String>{};
  }

  // Build adjacency list and calculate in-degrees
  for (final entry in state.moduleDependencies.entries) {
    final moduleName = entry.key;
    final dependencies = entry.value;

    for (final dep in dependencies) {
      if (state.modulePaths.containsKey(dep)) {
        adjList[dep]!.add(moduleName);
        inDegree[moduleName] = (inDegree[moduleName] ?? 0) + 1;
      } else {
        Logger.warning('Unknown dependency: $dep for module $moduleName');
      }
    }
  }

  Logger.debug('In-degrees calculated:');
  if (state.verbose) {
    for (final entry in inDegree.entries) {
      Logger.debug('   ${entry.key}: ${entry.value}');
    }
  }

  // Queue for modules with no dependencies
  final queue = <String>[];
  for (final entry in inDegree.entries) {
    if (entry.value == 0) {
      queue.add(entry.key);
      Logger.debug('Initial queue member: ${entry.key}');
    }
  }

  // Process queue
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    state.buildOrder.add(current);

    Logger.debug('Processing: $current');

    // Update in-degrees of dependent modules
    for (final dependent in adjList[current]!) {
      final newDegree = (inDegree[dependent] ?? 0) - 1;
      inDegree[dependent] = newDegree;
      Logger.debug('   Updated $dependent in-degree to $newDegree');

      if (newDegree == 0) {
        queue.add(dependent);
        Logger.debug('   Added $dependent to queue');
      }
    }
  }

  // Check for circular dependencies
  if (state.buildOrder.length != state.modulePaths.length) {
    Logger.error('Circular dependency detected! Cannot determine build order.');
    Logger.error('Processed: ${state.buildOrder.length} out of ${state.modulePaths.length} modules');

    // Show which modules couldn't be processed
    for (final moduleName in state.modulePaths.keys) {
      if (!state.buildOrder.contains(moduleName)) {
        Logger.error('   Stuck module: $moduleName (remaining in-degree: ${inDegree[moduleName]})');
        final deps = state.moduleDependencies[moduleName] ?? <String>{};
        Logger.error('   Dependencies: ${deps.join(' ')}');
      }
    }

    exit(1);
  }

  Logger.success('Build order determined: ${state.buildOrder.length} modules');
  if (state.verbose) {
    Logger.info('Build order:');
    for (var i = 0; i < state.buildOrder.length; i++) {
      Logger.verbose('${i + 1}. ${state.buildOrder[i]}');
    }
  }
}

// Show build plan
void showBuildPlan() {
  Logger.info('📋 Build Plan');
  Logger.info('═════════════');

  // Group by wave
  var maxWave = 0;
  for (final wave in state.moduleBuildLevel.values) {
    if (wave > maxWave) {
      maxWave = wave;
    }
  }

  for (var wave = 0; wave <= maxWave; wave++) {
    log('');
    Logger.info('🌊 Wave $wave (can run in parallel):');

    for (final moduleName in state.buildOrder) {
      if (state.moduleBuildLevel[moduleName] == wave) {
        final deps = state.moduleDependencies[moduleName] ?? <String>{};
        if (deps.isNotEmpty) {
          Logger.info('   • $moduleName (depends on: ${deps.join(', ')})');
        } else {
          Logger.info('   • $moduleName (no dependencies)');
        }
      }
    }
  }
  log('');
}

// Create build logs directory
Future<void> setupBuildLogs() async {
  final logsDir = Directory(state.buildLogsDir);
  if (!logsDir.existsSync()) {
    await logsDir.create(recursive: true);
    Logger.debug('Created build logs directory: ${state.buildLogsDir}');
  }

  // Clean old logs
  try {
    await for (final file in logsDir.list()) {
      if (file is File && file.path.endsWith('.log')) {
        await file.delete();
      }
    }
  } on Exception catch (e) {
    Logger.debug('Error cleaning old logs: $e');
  }
}

// Check if module can be built
bool canBuildModule(String moduleName) {
  Logger.debug('Checking if $moduleName can be built...');

  final dependencies = state.moduleDependencies[moduleName] ?? <String>{};

  if (dependencies.isEmpty) {
    Logger.debug('   $moduleName has no dependencies, can build');
    return true;
  }

  for (final dep in dependencies) {
    if (state.moduleBuildStatus[dep] != BuildStatus.completed) {
      Logger.debug('   $moduleName waiting for $dep (status: ${state.moduleBuildStatus[dep]})');
      return false;
    }
  }

  Logger.debug('   $moduleName all dependencies satisfied, can build');
  return true;
}

// Build a single module
Future<Map<String, dynamic>> buildModule(String moduleName) async {
  final modulePath = state.modulePaths[moduleName]!;
  final logFile = '${state.buildLogsDir}/build_$moduleName.log';

  Logger.building('Building $moduleName ($modulePath)...');
  state.moduleBuildStatus[moduleName] = BuildStatus.building;

  if (state.dryRun) {
    Logger.info('[DRY RUN] Would build: $moduleName');
    state.moduleBuildStatus[moduleName] = BuildStatus.completed;
    return {'success': true, 'moduleName': moduleName};
  }

  // Create log file
  final logSink = File(logFile).openWrite()
    ..writeln('=== Build started at ${DateTime.now().toIso8601String()} ===')
    ..writeln('Module: $moduleName')
    ..writeln('Path: $modulePath')
    ..writeln('Command: dart run build_runner build -d')
    ..writeln('===================================\n');

  // Determine command
  final usesFvm = File('$modulePath/.fvm').existsSync();
  final command = usesFvm ? 'fvm' : 'dart';
  final args = usesFvm ? ['dart', 'run', 'build_runner', 'build', '-d'] : ['run', 'build_runner', 'build', '-d'];

  // Start process
  final buildProcess = await Process.start(
    command,
    args,
    workingDirectory: modulePath,
  );

  state.modulePids[moduleName] = buildProcess;
  state.currentlyBuilding.add(moduleName);

  // Handle output
  buildProcess.stdout.transform(utf8.decoder).listen(logSink.write);

  buildProcess.stderr.transform(utf8.decoder).listen(logSink.write);

  final exitCode = await buildProcess.exitCode;

  logSink.writeln('\n=== Build finished at ${DateTime.now().toIso8601String()} ===');
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
      // Show last 5 lines of error log
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
      } on Exception catch (e) {
        Logger.debug('Error reading log file: $e');
      }
    }

    return {'success': false, 'moduleName': moduleName};
  }
}

// Smart build execution
Future<bool> executeSmartBuild() async {
  Logger.info('🚀 Starting smart build process...');

  if (state.dryRun) {
    Logger.warning('DRY RUN MODE - No actual builds will be performed');
  }

  await setupBuildLogs();

  final totalModules = state.buildOrder.length;
  var completed = 0;
  var failed = 0;
  var currentWave = -1;

  Logger.info('Total modules to build: $totalModules');
  Logger.info('Max parallel builds: ${state.maxParallelBuilds}');

  while (completed < totalModules) {
    // Determine the next wave's level based on pending modules.
    var minWave = 999;
    var allModulesBuilt = true;
    for (final moduleName in state.buildOrder) {
      if (state.moduleBuildStatus[moduleName] == BuildStatus.pending) {
        allModulesBuilt = false;
        final wave = state.moduleBuildLevel[moduleName] ?? 0;
        if (wave < minWave) {
          minWave = wave;
        }
      }
    }

    // Break the loop if there are no more pending modules.
    if (allModulesBuilt) break;

    // Check for stalled state.
    // Find all pending modules in the current wave.
    final buildsInWave = state.buildOrder
        .where(
          (moduleName) =>
              state.moduleBuildStatus[moduleName] == BuildStatus.pending &&
              (state.moduleBuildLevel[moduleName] ?? 0) == minWave &&
              canBuildModule(moduleName),
        )
        .toList();

    if (state.currentlyBuilding.isEmpty && buildsInWave.isEmpty) {
      Logger.error('Build process stalled. Some modules cannot be built due to failed dependencies.');

      for (final moduleName in state.buildOrder) {
        if (state.moduleBuildStatus[moduleName] == BuildStatus.pending) {
          Logger.error('   Stuck: $moduleName');
          final deps = state.moduleDependencies[moduleName] ?? <String>{};
          for (final dep in deps) {
            if (state.moduleBuildStatus[dep] == BuildStatus.failed) {
              Logger.error('      → Blocked by failed: $dep');
            }
          }
        }
      }
      return false; // Return false to indicate failure.
    }

    if (buildsInWave.isEmpty) {
      // If no modules in the current wave are ready, something is wrong or
      // we need to wait for a build to finish to unblock a dependency.
      await Future.delayed(const Duration(milliseconds: 500));
      continue;
    }

    // Log the new wave and start the builds.
    currentWave = minWave;
    log('');
    Logger.info('🌊 Starting Wave $currentWave');
    Logger.info('================================');

    final buildFutures = <Future<Map<String, dynamic>>>[];
    for (final moduleName in buildsInWave) {
      buildFutures.add(buildModule(moduleName));
    }

    // Wait for all builds in the current wave to complete.
    await Future.wait(buildFutures);

    // Update counts after the wave completes.
    completed = 0;
    failed = 0;
    for (final moduleName in state.buildOrder) {
      final status = state.moduleBuildStatus[moduleName]!;
      if (status == BuildStatus.completed) {
        completed++;
      } else if (status == BuildStatus.failed) {
        failed++;
        completed++; // Count as processed
      }
    }

    // Progress update after each wave.
    final inProgress = state.currentlyBuilding.length;
    final pending = totalModules - completed;
    Logger.info(
      '📊 Progress: Completed: ${completed - failed}/$totalModules | Failed: $failed | In Progress: $inProgress | Pending: $pending',
    );
  }

  // Final report
  log('');
  Logger.info('════════════════════════════════════');
  Logger.info('📊 Build Summary');
  Logger.info('════════════════════════════════════');
  log('');

  final successful = completed - failed;
  Logger.info('   ✅ Successful: $successful');
  Logger.info('   ❌ Failed: $failed');
  Logger.info('   📦 Total: $totalModules');

  if (failed > 0) {
    log('');
    Logger.error('Failed modules:');
    for (final moduleName in state.buildOrder) {
      if (state.moduleBuildStatus[moduleName] == BuildStatus.failed) {
        Logger.error('   • $moduleName → Check: ${state.buildLogsDir}/build_$moduleName.log');
      }
    }
  }

  log('');
  if (failed == 0) {
    Logger.success('🎉 All builds completed successfully!');
    return true;
  } else {
    Logger.error('💥 Some builds failed. Check individual log files in ${state.buildLogsDir}/');
    return false;
  }
}

Future<void> main(List<String> args) async {
  log('');
  Logger.info('🎯 Flutter Smart Build System v2.0 (Dart)');
  Logger.info('════════════════════════════════════════');
  log('');

  try {
    // Parse arguments
    parseArguments(args);

    // Show configuration
    if (state.verbose) {
      Logger.debug('Configuration:');
      Logger.debug('   Verbose: ${state.verbose}');
      Logger.debug('   Dry Run: ${state.dryRun}');
      Logger.debug('   Max Parallel: ${state.maxParallelBuilds}');
      Logger.debug('   Target Module: ${state.targetModule ?? 'all'}');
      Logger.debug('   Working Directory: ${Directory.current.path}');
      log('');
    }

    // Validate environment
    await validateEnvironment();

    // Set up signal handlers
    ProcessSignal.sigint.watch().listen((_) => cleanup());
    ProcessSignal.sigterm.watch().listen((_) => cleanup());

    if (state.targetModule != null) {
      Logger.info('🎯 Building specific module: ${state.targetModule}');

      await discoverModulesFromRoot();

      if (state.modulePaths.containsKey(state.targetModule)) {
        // Build dependency graph for single module
        await buildDependencyGraph();

        // Find all dependencies of target module
        final requiredModules = <String>{state.targetModule!};

        // Recursively find all dependencies
        var changed = true;
        while (changed) {
          changed = false;
          for (final moduleName in requiredModules.toList()) {
            final dependencies = state.moduleDependencies[moduleName] ?? <String>{};
            for (final dep in dependencies) {
              if (!requiredModules.contains(dep)) {
                requiredModules.add(dep);
                changed = true;
                Logger.debug('Added required dependency: $dep');
              }
            }
          }
        }

        // Filter to only required modules
        final modulesToRemove = <String>[];
        for (final moduleName in state.modulePaths.keys) {
          if (!requiredModules.contains(moduleName)) {
            modulesToRemove.add(moduleName);
          }
        }

        for (final moduleName in modulesToRemove) {
          state.modulePaths.remove(moduleName);
          state.moduleDependencies.remove(moduleName);
          state.moduleBuildStatus.remove(moduleName);
        }

        Logger.info(
          'Building ${state.targetModule} with ${requiredModules.length} total modules (including dependencies)',
        );

        calculateBuildLevels();
        topologicalSort();

        if (state.verbose || state.dryRun) {
          showBuildPlan();
        }

        if (!state.dryRun) {
          await executeSmartBuild();
        }
      }
    } else {
      // Full smart build
      await discoverModulesFromRoot();

      if (state.modulePaths.isEmpty) {
        Logger.error('No modules with build_runner found!');
        exit(1);
      }

      await buildDependencyGraph();
      calculateBuildLevels();
      await generateMermaidGraph();
      topologicalSort();

      if (state.verbose || state.dryRun) {
        showBuildPlan();
      }

      if (!state.dryRun) {
        await executeSmartBuild();
      }
    }

    log('');
    Logger.success('🏁 Smart build process completed!');
    log('');

    // Show helpful information
    if (!state.dryRun && File('build_graph.md').existsSync()) {
      Logger.info('📊 View dependency graph: build_graph.md');
    }
    if (!state.dryRun && Directory(state.buildLogsDir).existsSync()) {
      Logger.info('📁 Build logs available in: ${state.buildLogsDir}/');
    }
    exit(0);
  } on Exception catch (e, stackTrace) {
    Logger.error('Fatal error: $e');
    if (state.verbose) {
      log(stackTrace);
    }
    exit(1);
  }
}
