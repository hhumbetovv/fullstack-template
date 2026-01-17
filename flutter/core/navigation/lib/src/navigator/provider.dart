import 'package:core_navigation/src/core/nav_key.dart';
import 'package:core_presentation/exports.dart';
import 'package:flutter/material.dart';
import 'package:processor/public.dart';

import 'view_model.dart';

part 'provider.g.dart';

@provider
final class NavigatorProvider extends _NavigatorProvider {
  const NavigatorProvider({
    required this.stack,
    super.key,
    super.child,
  });

  final List<NavKey> stack;

  @override
  NavigatorViewModel viewModelFactory(BuildContext context) {
    return NavigatorViewModel(stack: stack);
  }
}
