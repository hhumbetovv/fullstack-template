import 'package:build/build.dart';

/// Aggregates frequently accessed values for a build step so helper services
/// don't need to depend directly on [BuildStep].
class GeneratorContext {
  GeneratorContext({
    required this.buildStep,
  });

  final BuildStep buildStep;

  AssetId get inputId => buildStep.inputId;

  AssetId get primaryOutput => buildStep.allowedOutputs.first;

  /// Example: `feature/src/foo.dart`.
  String get inputPath => buildStep.inputId.path;

  /// Example: `foo.dart`.
  String get inputFileName => buildStep.inputId.pathSegments.last;

  /// Example: `feature/src/foo` (without `.dart`).
  String get partFileBasePath {
    final segments = inputPath.split('.')..removeLast();
    return segments.join('.');
  }
}
