import 'package:flutter/widgets.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';

final class UiBottomSheet extends StatelessWidget {
  const UiBottomSheet({
    required this.child,
    super.key,
    this.title,
    this.titleStyle = Styles.bottomSheetTitle,
    this.subTitleStyle = Styles.bottomSheetSubTitle,
    this.subTitle,
    this.contentPadding = const AppPadding.largeV(),
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.background,
    this.physics = const NeverScrollableScrollPhysics(),
    this.titleColor,
  });

  final String? title;
  final TextStyle titleStyle;
  final Color? titleColor;
  final Widget child;
  final String? subTitle;
  final TextStyle subTitleStyle;
  final EdgeInsets contentPadding;
  final CrossAxisAlignment crossAxisAlignment;
  final Color? background;
  final ScrollPhysics physics;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      width: double.maxFinite,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: background ?? palette.bottomSheet.background,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.largeTop(),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const AppPadding.baseH(),
            child: SingleChildScrollView(
              physics: physics,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: crossAxisAlignment,
                children: [
                  const AppSpacing.smallV(),
                  const BottomSheetIndicator(),
                  if (title != null)
                    Padding(
                      padding: const AppPadding.largeT(),
                      child: UiText(
                        title!,
                        style: titleStyle,
                        color: titleColor,
                      ),
                    ),
                  if (subTitle != null)
                    Padding(
                      padding: const AppPadding.smallT(),
                      child: UiText(
                        subTitle!,
                        style: subTitleStyle,
                        color: palette.color.caption,
                      ),
                    ),
                  Padding(
                    padding: contentPadding,
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class BottomSheetIndicator extends StatelessWidget {
  const BottomSheetIndicator({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final color = context.palette.bottomSheet.indicator;
    return Center(
      child: SizedBox(
        width: 42,
        height: 5,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            color: color,
          ),
        ),
      ),
    );
  }
}
