import 'package:core_navigation/public.dart';

class EntryScope {
  EntryScope();

  final List<NavEntry> _entries = [];

  List<NavEntry> getEntries() => List.unmodifiable(_entries);

  void entries(EntryScopeBuilder builder) {
    builder(this);
  }

  void entry<T extends NavKey>({
    required NavWidgetBuilder builder,
    bool initial = false,
  }) {
    _entries.add(NavEntry<T>(builder: builder, initial: initial));
  }

  void addAll(List<NavEntry<NavKey>> entries) {
    _entries.addAll(entries);
  }
}
