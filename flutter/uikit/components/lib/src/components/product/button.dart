import 'package:common_presentation/public.dart';
import 'package:flutter/material.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';

final class UIButton extends StatefulWidget {
  const UIButton({
    required this.palette,
    this.text,
    this.height = AppDefaults.buttonHeight,
    this.isDisabled = false,
    this.isLoading = false,
    super.key,
    this.onClick,
    this.radius = const AppRadius.large(),
    this.suffixIcon,
    this.prefixIcon,
    this.suffixColor,
    this.prefixColor,
    this.removeSpacing = false,
    this.style = Styles.button,
    this.textSpan,
    this.content,
    this.expands = false,
    this.onSuffixTap,
    this.mainAxisAlignment = MainAxisAlignment.center,
  }) : assert(
         !(textSpan != null && text != null),
         'Only one of these can be set.',
       ),
       assert(
         !(textSpan == null && text == null && content == null),
         'One of these must be set: textSpan, text or children',
       );

  final VoidCallback? onClick;
  final VoidCallback? onSuffixTap;
  final ButtonTypePalette palette;
  final String? text;
  final List<InlineSpan>? textSpan;
  final TextStyle style;
  final bool isDisabled;
  final bool isLoading;
  final BorderRadius radius;
  final double height;
  final IconData? suffixIcon;
  final Color? suffixColor;
  final IconData? prefixIcon;
  final Color? prefixColor;
  final bool removeSpacing;
  final Widget? content;
  final bool expands;
  final MainAxisAlignment mainAxisAlignment;

  @override
  State<UIButton> createState() => _UIButtonState();
}

class _UIButtonState extends State<UIButton> {
  double animationValue = 0;

  Widget content() {
    if (widget.isLoading) {
      return Center(
        child: Loader(
          size: AppDefaults.buttonLoaderSize,
          color: widget.palette.content,
        ),
      );
    }

    return Row(
      mainAxisAlignment: widget.mainAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        prefixIcon(),
        if (!widget.removeSpacing) const Spacer(),
        buttonContent(),
        if (!widget.removeSpacing) const Spacer(),
        suffixIcon(),
      ],
    );
  }

  Widget prefixIcon() {
    if (widget.prefixIcon == null && widget.suffixIcon == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const AppPadding.smallL(),
      child: widget.prefixIcon != null
          ? UiIcon(
              widget.prefixIcon!,
              color: widget.prefixColor ?? widget.palette.content,
            )
          : const SizedBox(width: AppDefaults.iconSize),
    );
  }

  Widget buttonContent() {
    Widget? child;
    if (widget.content != null) {
      child = widget.content;
    } else {
      final style = widget.style.colored(
        widget.palette.content,
      );
      if (widget.textSpan != null) {
        child = RichText(
          text: TextSpan(
            style: style,
            children: widget.textSpan,
          ),
        );
      } else {
        child = UiText(widget.text ?? '', style: style);
      }
      child = FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const AppPadding.smallH(),
          child: child,
        ),
      );
    }
    if (widget.expands) {
      return Expanded(child: child!);
    }
    return child!;
  }

  Widget suffixIcon() {
    if (widget.suffixIcon == null && widget.prefixIcon == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const AppPadding.smallR(),
      child: widget.suffixIcon != null
          ? Clickable(
              onTap: widget.onSuffixTap,
              child: UiIcon(
                widget.suffixIcon!,
                color: widget.suffixColor ?? widget.palette.content,
              ),
            )
          : const SizedBox(width: AppDefaults.iconSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const AppDuration.fast(),
      child: Clickable(
        onTap: widget.onClick,
        onAnimationChanged: (value) => setState(() => animationValue = value),
        isDisabled: widget.isDisabled || widget.isLoading,
        pressedOpacity: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.radius,
            color: Color.lerp(
              widget.palette.background,
              widget.palette.pressedBackground,
              animationValue,
            ),
            border: Border.all(color: widget.palette.border),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: widget.height,
            ),
            child: Padding(
              padding: const AppPadding.small(),
              child: content(),
            ),
          ),
        ),
      ),
    );
  }
}
