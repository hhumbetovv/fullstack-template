import 'package:core_navigation/public.dart';

class EntryProvider {
  EntryProvider();

  final EntryScope _scope = EntryScope();
  EntryScope get scope => _scope;

  List<NavEntry> getEntries() => _scope.getEntries();

  void entries(EntryScopeBuilder builder) {
    builder(_scope);
  }

  void entry<T extends NavKey>({
    required NavWidgetBuilder<T> builder,
  }) {
    _scope.entry<T>(builder: builder);
  }

  void include(EntryProvider scope) {
    _scope.addAll(scope.getEntries());
  }
}
