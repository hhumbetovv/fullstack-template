import 'package:processor/processor.dart';

part 'state.g.dart';

@data
class FirstState {
  const factory FirstState({
    @Default(0) int value,
  }) = _FirstState;
}
