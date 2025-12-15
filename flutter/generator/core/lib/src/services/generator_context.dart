import 'package:build/build.dart';
import 'package:path/path.dart' as p;

/// Aggregates frequently accessed values for a build step so helper services
/// don't need to depend directly on [BuildStep].
class GeneratorContext {
  GeneratorContext({
    required this.buildStep,
  });

  final BuildStep buildStep;

  AssetId get inputId => buildStep.inputId;

  AssetId get primaryOutput {
    for (final output in buildStep.allowedOutputs) {
      if (p.extension(output.path) == '.dart') {
        return output;
      }
    }
    return buildStep.allowedOutputs.first;
  }

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
