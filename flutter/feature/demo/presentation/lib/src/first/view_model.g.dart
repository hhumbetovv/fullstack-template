// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// ViewModel Generator
// **************************************************************************

part of 'view_model.dart';

sealed class FirstIntent {
  const FirstIntent();
}

final class FirstMethod extends FirstIntent {
  const FirstMethod();

  @override
  String toString() {
    return 'FirstMethod';
  }
}

typedef FirstEffect = Unit;

abstract class _FirstViewModel
    extends BaseViewModel<FirstIntent, FirstState, FirstEffect> {
  _FirstViewModel();

  void _postIntent(FirstIntent intent) => super.postIntent(intent);

  @override
  Future<void> onIntentUpdate(FirstIntent intent) async {
    return switch (intent) {
      FirstMethod() => (this as FirstViewModel)._method(),
    };
  }
}

void firstIntent(BuildContext context, FirstIntent intent) {
  if (!context.mounted) return;
  context.read<FirstViewModel>()._postIntent(intent);
}

Value firstSelect<Value>(
  BuildContext context,
  Value Function(FirstState state) selector,
) {
  return context.select<FirstViewModel, Value>(
    (viewModel) => selector(viewModel.state),
  );
}

FirstState firstState(BuildContext context, {bool watch = false}) {
  if (watch) return context.watch<FirstViewModel>().state;
  return context.read<FirstViewModel>().state;
}
