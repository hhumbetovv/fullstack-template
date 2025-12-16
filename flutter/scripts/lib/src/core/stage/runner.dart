import 'dart:async';

/// Basic stage interface used to compose command pipelines.
abstract class Stage<T> {
  String get name;
  FutureOr<T> run(T context);
}

/// Sequentially executes a list of [Stage]s with a shared context object.
class StageRunner<T> {
  const StageRunner({required this.stages});

  final List<Stage<T>> stages;

  Future<T> run(T context) async {
    var current = context;
    for (final stage in stages) {
      current = await stage.run(current);
    }
    return current;
  }
}
