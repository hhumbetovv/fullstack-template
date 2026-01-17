import 'package:core_navigation/public.dart';
import 'package:core_navigation/src/navigator/view_model.dart';
import 'package:core_presentation/exports.dart';
import 'package:flutter/material.dart' hide NavigatorState;

export 'package:core_navigation/src/navigator/provider.dart';

final class NavDisplay extends StatelessWidget {
  const NavDisplay({
    required this.entryProvider,
    this.observers = const <NavigatorObserver>[],
    super.key,
  });

  final EntryProviderBuilder entryProvider;
  final List<NavigatorObserver> observers;

  @override
  Widget build(BuildContext context) {
    final entryProviderScope = EntryProvider();
    entryProvider(entryProviderScope);
    final entries = entryProviderScope.getEntries();

    final content = StateSelector<NavigatorViewModel, NavigatorState, List<NavKey>>(
      selector: (state) => state.backStack,
      builder: (context, backStack, child) {
        final pages = backStack
            .map((key) {
              final entry = entries.where((entry) => entry.predicate(key)).firstOrNull;
              if (entry == null) return null;
              return MaterialPage<void>(
                key: ValueKey(key.name),
                name: key.name,
                child: entry.build(key),
              );
            })
            .whereType<Page<dynamic>>()
            .toList();
        if (pages.isEmpty) {
          return const SizedBox.shrink();
        }
        return Navigator(
          pages: pages,
          observers: observers,
          onDidRemovePage: (page) {
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
          },
        );
      },
    );
    return content;
  }
}
