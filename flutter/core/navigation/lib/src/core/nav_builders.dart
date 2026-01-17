import 'package:core_navigation/src/core/nav_key.dart';
import 'package:core_navigation/src/entry_provider/entry_provider.dart';
import 'package:core_navigation/src/entry_provider/entry_scope.dart';
import 'package:flutter/widgets.dart';

typedef NavBuilder = List<NavKey> Function(List<NavKey> stack);
typedef NavWidgetBuilder<T extends NavKey> = Widget Function(T key);
typedef RouteBuilder<T> = Widget Function(BuildContext context, T? arguments);
typedef EntryScopeBuilder = void Function(EntryScope scope);
typedef EntryProviderBuilder = void Function(EntryProvider provider);
