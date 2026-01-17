import 'package:core_presentation/exports.dart';
import 'package:demo_domain/public.dart';
import 'package:processor/processor.dart';

import 'state.dart';

export 'state.dart';

part 'view_model.g.dart';

@viewModel
final class FirstViewModel extends _FirstViewModel {
  @override
  FirstState get initialState => const FirstState();

  final _demoUseCase = inject<DemoUseCase>();

  @intent
  void _method() {
    final result = _demoUseCase();
    if (state.value == result) {
      postEffect(const FirstEffect.showSnackBar());
    } else {
      setState(state.applyValue(result));
    }
  }
}
