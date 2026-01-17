import 'package:core_navigation/src/core/nav_key.dart';
import 'package:flutter/widgets.dart';

class NavEntry<T extends NavKey> {
  const NavEntry({
    required this.builder,
    this.initial = false,
  });

  final Widget Function(T key) builder;
  final bool initial;

  bool predicate(NavKey key) => key is T;
  Widget build(NavKey key) => builder(key as T);
}
