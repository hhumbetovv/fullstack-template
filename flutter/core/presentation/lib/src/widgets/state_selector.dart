import 'package:core_presentation/src/state/base_view_model.dart';
import 'package:provider/provider.dart';

final class StateSelector<VModel extends BaseViewModel<dynamic, VState, dynamic>, VState, Value>
    extends Selector<VModel, Value> {
  StateSelector({
    required Value Function(VState state) selector,
    required super.builder,
    bool Function(Value oldValue, Value newValue)? buildWhen,
    super.child,
    super.key,
  }) : super(
         shouldRebuild: buildWhen,
         selector: (context, viewModel) {
           return selector(viewModel.state);
         },
       );
}
