import 'package:core_presentation/src/state/base_view_model.dart';
import 'package:processor/public.dart';
import 'package:provider/provider.dart';

final class StateBuilder<VModel extends BaseViewModel<dynamic, VState, dynamic>, VState>
    extends Selector<VModel, VState> {
  StateBuilder({
    required super.builder,
    List<dynamic> Function(VState state)? depends,
    super.child,
    super.key,
  }) : super(
         shouldRebuild: depends == null
             ? null
             : (oldState, newState) {
                 final oldFields = depends.call(oldState);
                 final newFields = depends.call(newState);
                 return !isEquals(oldFields, newFields);
               },
         selector: (context, viewModel) {
           return viewModel.state;
         },
       );
}
