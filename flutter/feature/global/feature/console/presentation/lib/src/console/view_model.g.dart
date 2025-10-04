// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// ViewModel Generator
// **************************************************************************

part of 'view_model.dart';

sealed class ConsoleIntent {
  const ConsoleIntent();

  const factory ConsoleIntent.refresh() = _ConsoleRefresh;

  const factory ConsoleIntent.toggleTag(String value) = _ConsoleToggleTag;

  const factory ConsoleIntent.setQuery(String value) = _ConsoleSetQuery;

  const factory ConsoleIntent.shareLogs() = _ConsoleShareLogs;

  const factory ConsoleIntent.copyLogs() = _ConsoleCopyLogs;

  const factory ConsoleIntent.clearLogs() = _ConsoleClearLogs;

  void dispatch(BuildContext context) {
    if (!context.mounted) return;
    context.read<ConsoleViewModel>()._postIntent(this);
  }
}

final class _ConsoleRefresh extends ConsoleIntent {
  const _ConsoleRefresh();

  @override
  String toString() {
    return '_ConsoleRefresh';
  }
}

final class _ConsoleToggleTag extends ConsoleIntent {
  const _ConsoleToggleTag(this.value);

  final String value;

  @override
  String toString() {
    return '_ConsoleToggleTag { value: $value }';
  }
}

final class _ConsoleSetQuery extends ConsoleIntent {
  const _ConsoleSetQuery(this.value);

  final String value;

  @override
  String toString() {
    return '_ConsoleSetQuery { value: $value }';
  }
}

final class _ConsoleShareLogs extends ConsoleIntent {
  const _ConsoleShareLogs();

  @override
  String toString() {
    return '_ConsoleShareLogs';
  }
}

final class _ConsoleCopyLogs extends ConsoleIntent {
  const _ConsoleCopyLogs();

  @override
  String toString() {
    return '_ConsoleCopyLogs';
  }
}

final class _ConsoleClearLogs extends ConsoleIntent {
  const _ConsoleClearLogs();

  @override
  String toString() {
    return '_ConsoleClearLogs';
  }
}

typedef ConsoleEffect = Unit;

abstract class _ConsoleViewModel
    extends BaseViewModel<ConsoleIntent, ConsoleState, ConsoleEffect> {
  _ConsoleViewModel();

  void _postIntent(ConsoleIntent intent) => super.postIntent(intent);

  @override
  Future<void> onIntentUpdate(ConsoleIntent intent) async {
    return switch (intent) {
      _ConsoleRefresh() => (this as ConsoleViewModel)._refresh(),
      _ConsoleToggleTag() => (this as ConsoleViewModel)._toggleTag(
        intent.value,
      ),
      _ConsoleSetQuery() => (this as ConsoleViewModel)._setQuery(intent.value),
      _ConsoleShareLogs() => (this as ConsoleViewModel)._shareLogs(),
      _ConsoleCopyLogs() => (this as ConsoleViewModel)._copyLogs(),
      _ConsoleClearLogs() => (this as ConsoleViewModel)._clearLogs(),
    };
  }
}

Value consoleSelect<Value>(
  BuildContext context,
  Value Function(ConsoleState state) selector,
) {
  return context.select<ConsoleViewModel, Value>(
    (viewModel) => selector(viewModel.state),
  );
}

ConsoleState consoleState(BuildContext context, {bool watch = false}) {
  if (watch) return context.watch<ConsoleViewModel>().state;
  return context.read<ConsoleViewModel>().state;
}
