import 'package:core_navigation/src/result/view_model.dart';
import 'package:core_presentation/exports.dart';
import 'package:flutter/widgets.dart';
import 'package:processor/public.dart';

final class ResultListener<T extends Object> extends StatelessWidget {
  const ResultListener({
    required this.onResult,
    required this.child,
    super.key,
    this.consumeOnce = true,
  });

  final Widget child;
  final bool consumeOnce;
  final void Function(BuildContext context, T value) onResult;

  @Effect(from: [ResultViewModel])
  void _onResult(BuildContext context, Object value, int timestamp) {
    final _ = timestamp;
    if (value is! T) return;
    onResult(context, value);
    if (consumeOnce) {
      ResultIntent.clearResult(T).dispatch(context);
    }
  }

  void _onEffectUpdate(BuildContext context, ResultEffect effect) {
    if (effect is ResultOnResult) {
      _onResult(context, effect.value, effect.timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelListener<ResultViewModel, ResultEffect>(
      onEffectUpdate: _onEffectUpdate,
      child: child,
    );
  }
}
