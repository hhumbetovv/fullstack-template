import 'package:core_navigation/src/result/model/result_entry.dart';
import 'package:core_navigation/src/result/state.dart';
import 'package:core_presentation/exports.dart';
import 'package:processor/public.dart';

part 'view_model.g.dart';

@viewModel
final class ResultViewModel extends _ResultViewModel {
  @override
  ResultState get initialState => const ResultState();

  @override
  bool get logEffects => false;

  @override
  bool get logEvents => false;

  @override
  bool get logIntents => false;

  @override
  bool get logState => false;

  ResultEntry<T>? getResult<T extends Object>() => state.results[T] as ResultEntry<T>?;

  @intent
  void _setResult(Type type, Object value) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final entry = ResultEntry<Object>(value: value, timestamp: timestamp);
    final updated = Map<Type, ResultEntry<dynamic>>.from(state.results);
    updated[type] = entry;
    setState(state.copy(results: updated));
    postEffect(ResultEffect.onResult(value, timestamp));
  }

  @intent
  void _clearResult(Type type) {
    if (!state.results.containsKey(type)) return;
    final updated = Map<Type, ResultEntry<dynamic>>.from(state.results)..remove(type);
    setState(state.copy(results: updated));
  }

  @intent
  void _clearAllResults() {
    if (state.results.isEmpty) return;
    setState(state.copy(results: const <Type, ResultEntry<dynamic>>{}));
  }

  void clearResult<T extends Object>() => _clearResult(T);

  void clearAll() => _clearAllResults();
}
