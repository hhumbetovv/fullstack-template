import 'package:common_presentation/config.dart';
import 'package:common_presentation/constants.dart';
import 'package:core_presentation/src/state/base_view_model.dart';
import 'package:core_presentation/src/state/state_notifier.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class ViewModelProvider<VM extends BaseViewModel<dynamic, dynamic, Effect>, Effect> extends SingleChildStatelessWidget {
  const ViewModelProvider({
    required Create<VM> create,
    super.key,
    this.child,
    this.lazy = true,
  }) : _create = create,
       _value = null,
       super(child: child);

  const ViewModelProvider.value({
    required VM value,
    super.key,
    this.child,
  }) : _value = value,
       _create = null,
       lazy = true,
       super(child: child);

  final Widget? child;

  final bool lazy;

  final Create<VM>? _create;

  final VM? _value;

  VoidCallback _startListening(
    InheritedContext<BaseViewModel<dynamic, dynamic, Effect>?> context,
    BaseViewModel<dynamic, dynamic, Effect> viewModel,
  ) {
    final StateListener<dynamic> listener = (
      listener: (_) {
        context.markNeedsNotifyDependents();
      },
      condition: null,
    );
    viewModel.addListener(listener);

    final messageSubscription = viewModel.messageStream.listen((message) {
      messengerKey.currentState?.showSnackBar(
        CommonPresentationConfig().snackBarBuilder(message.content, message.type),
      );
    });

    return () {
      viewModel.removeListener(listener);
      messageSubscription.cancel();
    };
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    assert(
      child != null,
      '$runtimeType used outside of ViewModelProvider must specify a child',
    );
    final value = _value;

    return value != null
        ? InheritedProvider<VM>.value(
            value: value,
            lazy: lazy,
            startListening: _startListening,
            child: child,
          )
        : InheritedProvider<VM>(
            create: _create,
            dispose: (_, viewModel) => viewModel.dispose(),
            startListening: _startListening,
            lazy: lazy,
            child: child,
          );
  }
}
