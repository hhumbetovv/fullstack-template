import 'package:core_navigation/src/result/model/result_entry.dart';
import 'package:processor/public.dart';

part 'state.g.dart';

@data
class ResultState {
  const factory ResultState({
    @Default(<Type, ResultEntry<dynamic>>{})
    Map<Type, ResultEntry<dynamic>> results,
  }) = _ResultState;
}
