import 'dart:async';

import 'package:core_presentation/src/state/base_view_model.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class ViewModelListener<VModel extends BaseViewModel<dynamic, dynamic, VEffect>, VEffect>
    extends SingleChildStatefulWidget {
  const ViewModelListener({
    required this.onEffectUpdate,
    super.key,
    this.viewModel,
    this.child,
  }) : super(child: child);

  final Widget? child;

  final VModel? viewModel;

  final void Function(BuildContext context, VEffect effect) onEffectUpdate;

  @override
  SingleChildState<ViewModelListener<VModel, VEffect>> createState() => _ViewModelListenerState<VModel, VEffect>();
}

class _ViewModelListenerState<VModel extends BaseViewModel<dynamic, dynamic, VEffect>, VEffect>
    extends SingleChildState<ViewModelListener<VModel, VEffect>> {
  StreamSubscription<VEffect>? _subscription;
  late VModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? context.read<VModel>();
    _subscribe();
  }

  @override
  void didUpdateWidget(ViewModelListener<VModel, VEffect> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldViewModel = oldWidget.viewModel ?? context.read<VModel>();
    final currentViewModel = widget.viewModel ?? oldViewModel;
    if (oldViewModel != currentViewModel) {
      if (_subscription != null) {
        _unsubscribe();
        _viewModel = currentViewModel;
      }
      _subscribe();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = widget.viewModel ?? context.read<VModel>();
    if (_viewModel != viewModel) {
      if (_subscription != null) {
        _unsubscribe();
        _viewModel = viewModel;
      }
      _subscribe();
    }
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    assert(
      child != null,
      '''${widget.runtimeType} used outside of ViewModelListener must specify a child''',
    );
    if (widget.viewModel == null) {
      context.select<VModel, bool>((viewModel) => identical(_viewModel, viewModel));
    }
    return child!;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    _subscription = _viewModel.effectStream.listen((effect) {
      if (mounted) widget.onEffectUpdate(context, effect);
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }
}
