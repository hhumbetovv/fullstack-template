import 'package:app/config/router.dart';
import 'package:auto_route/auto_route.dart';
import 'package:common_shared/public.dart';
import 'package:console_presentation/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_components/public.dart';

@RoutePage()
final class RootView extends StatelessWidget {
  const RootView({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext parentContext) {
    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) {
            final palette = context.palette;
            return Stack(
              children: [
                AnnotatedRegion(
                  value: SystemUiOverlayStyle(
                    statusBarColor: Colors.black.withAlpha(1),
                    systemNavigationBarColor: palette.color.background,
                    statusBarBrightness: palette.core.brightness,
                    statusBarIconBrightness: palette.core.contentBrightness,
                    systemNavigationBarIconBrightness: palette.core.brightness,
                  ),
                  child: Scaffold(
                    backgroundColor: palette.color.background,
                    body: Builder(
                      builder: (context) {
                        final widget = GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            FocusScope.of(context).focusedChild?.unfocus();
                          },
                          // TODO: Handle Keyboard Visibility
                          child: child,
                        );
                        if (Console.isEnabled) {
                          return KonamiSwipeDetector(
                            onDetect: () {
                              AppRouter.instance.navigate(const ConsoleRoute());
                            },
                            child: widget,
                          );
                        }
                        return widget;
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
