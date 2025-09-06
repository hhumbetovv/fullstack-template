import 'package:core_presentation/state.dart';
import 'package:demo_domain/usecase.dart';
import 'package:processor/processor.dart';

import 'state.dart';

export 'state.dart';

part 'view_model.g.dart';

@viewModel
final class FirstViewModel extends _FirstViewModel {
  @override
  FirstState get initialState => const FirstState();

  final _demoUseCase = useCase<DemoUseCase>();

  @override
  void onCreate() {
    _method();
  }

  @intent
  void _method() {
    final result = _demoUseCase();

    setState(state.copy(value: result));
  }
}
