import 'package:core_navigation/src/core/nav_builders.dart';
import 'package:core_navigation/src/core/nav_key.dart';
import 'package:core_presentation/exports.dart';
import 'package:processor/public.dart';

import 'state.dart';

export 'state.dart';

part 'view_model.g.dart';

@viewModel
final class NavigatorViewModel extends _NavigatorViewModel {
  NavigatorViewModel({
    required this.stack,
  });

  final List<NavKey> stack;

  @override
  NavigatorState get initialState => NavigatorState(backStack: stack);

  @override
  bool get logEffects => false;
  @override
  bool get logEvents => false;
  @override
  bool get logIntents => false;
  @override
  bool get logState => false;

  @intent
  void _buildStack(NavStackBuilder builder) {
    setState(
      state.applyBackStack(
        builder([...state.backStack]),
      ),
    );
  }
}
