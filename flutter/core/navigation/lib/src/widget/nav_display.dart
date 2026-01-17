import 'package:common_shared/public.dart';
import 'package:core_navigation/public.dart';
import 'package:core_navigation/src/navigator/view_model.dart';
import 'package:core_presentation/exports.dart';
import 'package:flutter/material.dart' hide NavigatorState;

export 'package:core_navigation/src/navigator/provider.dart';

part 'nav_display_mixin.dart';

final class NavDisplay extends StatelessWidget with _NavDisplayMixin {
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
        final pages = createPages(entries, backStack);

        if (pages.isEmpty) {
          return const SizedBox.shrink();
        }
        return Navigator(
          pages: pages,
          observers: observers,
          onDidRemovePage: (page) {
            pop(context, page);
          },
        );
      },
    );
    return content;
  }
}
