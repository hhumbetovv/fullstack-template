import 'package:core_presentation/src/state/base_view_model.dart';
import 'package:provider/provider.dart';

final class StateBuilder<VModel extends BaseViewModel<dynamic, VState, dynamic>, VState>
    extends Selector<VModel, VState> {
  StateBuilder({
    required super.builder,
    bool Function(VState oldState, VState newState)? buildWhen,
    super.child,
    super.key,
  }) : super(
         shouldRebuild: buildWhen,
         selector: (context, viewModel) {
           return viewModel.state;
         },
       );
}
