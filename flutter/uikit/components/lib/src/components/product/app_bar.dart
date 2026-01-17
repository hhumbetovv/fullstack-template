import 'package:flutter/material.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';

final class UiAppBar extends StatelessWidget {
  const UiAppBar({
    super.key,
    this.trailing,
    this.title,
    this.subTitle,
    this.content,
    this.bottom,
    this.showBackButton = false,
    this.verticalSpacing = AppDimens.small,
    this.onBackButtonClicked,
    this.isLoading = false,
    this.horizontalPadding = const AppPadding.baseH(),
  });

  final String? title;
  final String? subTitle;
  final bool showBackButton;
  final VoidCallback? onBackButtonClicked;

  final Widget? content;
  final Widget? trailing;

  final Widget? bottom;
  final double verticalSpacing;
  final bool isLoading;

  final EdgeInsets horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette.color;

    void onBackClick() {
      (onBackButtonClicked ?? Navigator.of(context).pop).call();
    }

    return Stack(
      children: [
        Positioned(
          child: AnimatedVisibility(
            isVisible: isLoading,
            child: LinearProgressIndicator(
              color: palette.primary,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        Padding(
          padding: const AppPadding.smallV(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: horizontalPadding,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppDefaults.appBarHeight,
                  ),
                  child: Row(
                    children: [
                      if (subTitle == null && showBackButton && title != null)
                        UiIconButton(
                          AppIcons.chevronLeft,
                          label: title,
                          labelSpacing: 18,
                          padding: const AppPadding.zero(),
                          labelStyle: Styles.s20Semibold,
                          onTap: onBackClick,
                        )
                      else ...[
                        if (showBackButton)
                          UiIconButton(
                            AppIcons.chevronLeft,
                            alignment: Alignment.centerLeft,
                            onTap: onBackClick,
                          ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: AppDimens.micro,
                            children: [
                              if (title != null)
                                Row(
                                  spacing: AppDimens.small,
                                  children: [
                                    UiText(
                                      title!,
                                      style: subTitle == null ? Styles.s20Semibold : Styles.s16Semibold,
                                    ),
                                  ],
                                ),
                              if (subTitle != null)
                                UiText(
                                  subTitle!,
                                  color: palette.caption,
                                ),
                            ],
                          ),
                        ),
                      ],
                      ?content,
                      if (trailing != null) ...[
                        const Spacer(),
                        trailing!,
                      ],
                    ],
                  ),
                ),
              ),
              if (bottom != null)
                Padding(
                  padding: EdgeInsets.only(top: verticalSpacing),
                  child: bottom,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
