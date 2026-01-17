part of 'nav_display.dart';

mixin _NavDisplayMixin on StatelessWidget {
  List<Page<dynamic>> createPages(
    List<NavEntry> entries,
    List<NavKey> backStack,
  ) {
    return backStack
        .mapIndexed((index, key) {
          final entry = entries.where((entry) {
            return entry.predicate(key);
          }).firstOrNull;
          if (entry == null) return null;
          return MaterialPage<void>(
            key: ValueKey('${key.name}-$index'),
            name: key.name,
            child: entry.build(key),
          );
        })
        .whereType<MaterialPage<dynamic>>()
        .toList();
  }

  void pop(BuildContext context, Page<Object?> page) {
    context.buildStack((stack) {
      final updated = [...stack];
      final key = page.key;
      final removedKey = page.name ?? (key is ValueKey<String> ? key.value : null);
      if (removedKey == null) {
        if (updated.isNotEmpty) {
          updated.removeLast();
        }
        return updated;
      }
      final index = updated.lastIndexWhere(
        (route) => route.name == removedKey,
      );
      if (index == -1) {
        if (updated.isNotEmpty) {
          updated.removeLast();
        }
        return updated;
      }
      updated.removeAt(index);
      return updated;
    });
  }
}
