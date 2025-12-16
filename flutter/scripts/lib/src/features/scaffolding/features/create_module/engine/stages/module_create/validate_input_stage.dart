import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/stage/runner.dart';
import 'package:scripts/src/features/scaffolding/features/create_module/engine/pipelines/module_create/module_create_context.dart';

class ValidateInputStage implements Stage<ModuleCreateContext> {
  ValidateInputStage(this.workspaceRoot);

  final String workspaceRoot;

  @override
  String get name => 'validate-input';

  @override
  Future<ModuleCreateContext> run(ModuleCreateContext context) async {
    final featureSegments = _normalizeSegments(context.featurePath);
    if (featureSegments.isEmpty) {
      throw const CommandError(
        'Provide a feature path (e.g. profile or profile/edit).',
        exitCode: 64,
      );
    }

    final normalizedModuleType = _normalizeSegment(context.moduleType);
    if (normalizedModuleType.isEmpty) {
      throw const CommandError(
        'Provide the module type to create (e.g. data_api, domain).',
        exitCode: 64,
      );
    }

    context
      ..featureSegments = featureSegments
      ..normalizedModuleType = normalizedModuleType;
    return context;
  }

  List<String> _normalizeSegments(String input) {
    return input
        .split(RegExp(r'[\\/]+'))
        .map(_normalizeSegment)
        .where((segment) => segment.isNotEmpty)
        .toList();
  }

  String _normalizeSegment(String input) {
    final trimmed = input.trim().toLowerCase();
    final replaced = trimmed.replaceAll(RegExp('[^a-z0-9]+'), '_');
    final collapsed = replaced.replaceAll(RegExp('_+'), '_');
    return collapsed.replaceAll(RegExp(r'^_|_$'), '');
  }
}
