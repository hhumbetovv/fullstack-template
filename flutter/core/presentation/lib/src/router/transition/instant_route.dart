import 'package:auto_route/auto_route.dart';

final class InstantRoute extends CustomRoute<void> {
  InstantRoute({
    required super.page,
    super.children,
    super.initial,
    super.path,
    super.guards,
    super.keepHistory,
  }) : super(
          duration: Duration.zero,
          reverseDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        );
}
