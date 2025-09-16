// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// ViewModel Generator
// **************************************************************************

part of 'view_model.dart';

sealed class FirstIntent {
  const FirstIntent();

  const factory FirstIntent.method() = _FirstMethod;

  void dispatch(BuildContext context) {
    if (!context.mounted) return;
    context.read<FirstViewModel>()._postIntent(this);
  }
}

final class _FirstMethod extends FirstIntent {
  const _FirstMethod();

  @override
  String toString() {
    return '_FirstMethod';
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
      _FirstMethod() => (this as FirstViewModel)._method(),
    };
  }
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
