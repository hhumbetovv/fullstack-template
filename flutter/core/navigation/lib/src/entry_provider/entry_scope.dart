import 'package:core_navigation/public.dart';

class EntryScope {
  EntryScope();

  final List<NavEntry> _entries = [];

  List<NavEntry> getEntries() => List.unmodifiable(_entries);

  void entries(EntryScopeBuilder builder) {
    builder(this);
  }

  void entry<T extends NavKey>({
    required NavWidgetBuilder<T> builder,
  }) {
    _entries.add(NavEntry<T>(builder: builder));
  }

  void addAll(Iterable<NavEntry> entries) {
    _entries.addAll(entries);
  }
}
