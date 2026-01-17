import 'package:core_navigation/src/core/nav_key.dart';
import 'package:flutter/widgets.dart';

class NavEntry<T extends NavKey> {
  NavEntry({
    required Widget Function(T key) builder,
    this.initial = false,
  }) : _builder = ((key) => builder(key as T));

  final Widget Function(NavKey key) _builder;
  final bool initial;

  bool predicate(NavKey key) => key is T;
  Widget build(NavKey key) => _builder(key);
}
