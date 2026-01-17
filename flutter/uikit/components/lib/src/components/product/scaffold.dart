import 'package:flutter/widgets.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';

final class UiScaffold extends StatelessWidget {
  const UiScaffold({
    required this.child,
    super.key,
    this.isEnabled = true,
    this.safeTop = true,
    this.safeBottom = true,
    this.appBar,
    this.bottomBar,
    this.expanded = true,
    this.padding = const AppPadding.baseH(),
    this.scrollable = true,
  });

  final bool isEnabled;
  final bool safeTop;
  final bool safeBottom;
  final Widget? appBar;
  final Widget child;
  final Widget? bottomBar;
  final EdgeInsets padding;
  final bool expanded;
  final bool scrollable;

  Widget buildChild() {
    var widget = child;
    if (scrollable) {
      widget = SingleChildScrollView(
        child: widget,
      );
    }
    widget = Padding(
      padding: padding,
      child: widget,
    );

    if (expanded) {
      widget = Expanded(
        child: widget,
      );
    }

    return widget;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.palette.color.background,
      child: SafeArea(
        top: safeTop,
        bottom: safeBottom,
        child: IgnorePointer(
          ignoring: !isEnabled,
          child: Column(
            children: [
              ?appBar,
              buildChild(),
              ?bottomBar,
            ],
          ),
        ),
      ),
    );
  }
}
