import 'dart:async';

/// Basic stage interface used to compose command pipelines.
abstract class Stage<T> {
  String get name;
  FutureOr<T> run(T context);
}

/// Sequentially executes a list of [Stage]s with a shared context object.
class StageRunner<T> {
  const StageRunner({
    required this.stages,
    this.onStageStart,
    this.onStageComplete,
  });

  final List<Stage<T>> stages;
  final void Function(String stageName)? onStageStart;
  final void Function(String stageName)? onStageComplete;

  Future<T> run(T context) async {
    var current = context;
    for (final stage in stages) {
      onStageStart?.call(stage.name);
      try {
        current = await stage.run(current);
      } finally {
        onStageComplete?.call(stage.name);
      }
    }
    return current;
  }
}
