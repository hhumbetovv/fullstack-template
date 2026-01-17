import 'package:core_navigation/src/core/nav_builders.dart';
import 'package:core_navigation/src/core/nav_key.dart';
import 'package:flutter/widgets.dart';

class NavEntry<T extends NavKey> {
  NavEntry({
    required NavWidgetBuilder<T> builder,
  }) : _builder = ((key) => builder(key as T));

  final Widget Function(NavKey key) _builder;

  bool predicate(NavKey key) => key is T;
  Widget build(NavKey key) => _builder(key);
}
