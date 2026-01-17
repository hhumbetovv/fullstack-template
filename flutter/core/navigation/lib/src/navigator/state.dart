import 'package:core_navigation/src/core/nav_key.dart';
import 'package:processor/public.dart';

part 'state.g.dart';

@data
class NavigatorState {
  const factory NavigatorState({
    @Default(<NavKey>[]) List<NavKey> backStack,
  }) = _NavigatorState;
}
