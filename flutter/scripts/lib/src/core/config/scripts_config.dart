sealed class BuildEngineConfig {
  static const int maxParallelBuilds = 8;
  static const String buildLogsDir = '.misc/build_logs';
}

sealed class CodegenBuildConfig {
  static const bool obfuscateAndroid = true;
  static const bool splitDebugInfo = true;
  static const String splitDebugInfoPath = './android/app/release';
  static const bool applyTargetPlatform = true;
  static const String targetPlatform = 'android-arm,android-arm64,android-x64';
  static const String artifactsDir = '.misc/artifacts';
}

sealed class CodegenGenCleanConfig {
  static const String defaultWorkers = 'auto';
}

sealed class LocaleConfig {
  static const String inputPath = 'app/assets/translations';
  static const String outputPath = 'common/lib/src/constants/locale_keys.dart';
}

sealed class ScaffoldingConfig {
  static const String workspaceConfigFile = 'pub_versions.yaml';
  static const String rootPubspecFile = 'pubspec.yaml';
  static const String lockFilePath = '.misc/build_info/modules_lock.yaml';
  static const String dependencyReportPath = '.misc/build_info/dependencies.md';
}

sealed class ModuleGraphConfig {
  static const String moduleGraphFile = 'module_graph.md';
  static const String overviewFile = 'overview.md';
}
