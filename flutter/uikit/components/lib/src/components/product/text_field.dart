import 'package:common_presentation/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';

final class UiTextField extends StatefulWidget {
  const UiTextField({
    this.denySpaces = false,
    this.inputFormatters,
    this.maxLength,
    this.keyboardType,
    this.label,
    this.hint,
    this.readOnly = false,
    this.enabled = true,
    this.expands = false,
    this.style = Styles.textField,
    this.radius = const AppRadius.large(),
    this.value,
    this.suffixIcon,
    this.onSuffixTap,
    this.onFocusChanged,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.controller,
    this.onChanged,
    this.focusNode,
    this.onPrefixTap,
    this.onTap,
    this.prefixIcon,
    super.key,
    this.error,
    this.initialValue,
    this.hideErrorText = false,
    this.maxLines = 1,
    this.minHeight = AppDefaults.textFieldHeight,
    this.maxHeight = AppDefaults.textFieldHeight,
    this.padding,
    this.textAlignVertical = TextAlignVertical.center,
    this.focused = false,
  });

  final bool readOnly;
  final bool enabled;
  final bool obscureText;
  final bool denySpaces;
  final bool hideErrorText;
  final bool expands;

  final String? value;
  final String? initialValue;
  final String? hint;
  final String? label;
  final String? error;
  final TextStyle style;
  final BorderRadius radius;
  final bool focused;

  final VoidCallback? onSuffixTap;
  final VoidCallback? onPrefixTap;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onFocusChanged;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  final EdgeInsets? padding;
  final FocusNode? focusNode;
  final AppIcons? suffixIcon;
  final AppIcons? prefixIcon;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int? maxLines;
  final double minHeight;
  final double maxHeight;
  final TextInputType? keyboardType;
  final TextAlignVertical textAlignVertical;

  @override
  State<UiTextField> createState() => _UiTextFieldState();
}

class _UiTextFieldState extends State<UiTextField> {
  late final FocusNode focusNode;
  late final TextEditingController controller;

  bool isFocused = false;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? TextEditingController();
    controller.text = widget.initialValue ?? '';
    focusNode = widget.focusNode ?? FocusNode();
    focusNode.addListener(onFocusChanged);
  }

  @override
  void dispose() {
    if (widget.focusNode != null) {
      focusNode.removeListener(onFocusChanged);
    } else {
      focusNode
        ..removeListener(onFocusChanged)
        ..dispose();
    }
    if (widget.controller == null) {
      controller.dispose();
    }
    super.dispose();
  }

  void onFocusChanged() {
    final value = focusNode.hasFocus;
    widget.onFocusChanged?.call(value);
    if (value != isFocused) {
      setState(() {
        isFocused = value;
      });
    }
  }

  @override
  void didUpdateWidget(covariant UiTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      controller.text = widget.value ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette.textField.primary;
    final fieldPalette = widget.error != null
        ? palette.error
        : isFocused && !widget.readOnly || widget.focused
        ? palette.focused
        : palette.idle;

    final border = OutlineInputBorder(
      borderRadius: widget.radius,
      borderSide: BorderSide(
        color: fieldPalette.border,
        width: 1.5,
      ),
    );

    return Clickable(
      disabledOpacity: 0.42,
      onTap: () {},
      child: IgnorePointer(
        ignoring: !widget.enabled,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null) ...[
              UiText(widget.label!, style: Styles.s14Semibold),
              const AppSpacing.smallV(),
            ],
            TextField(
              style: widget.style.colored(
                fieldPalette.text,
              ),
              onTap: widget.onTap,
              textAlignVertical: widget.textAlignVertical,
              focusNode: focusNode,
              controller: controller,
              obscureText: widget.obscureText,
              readOnly: widget.readOnly,
              expands: widget.expands,
              inputFormatters: [
                if (widget.inputFormatters != null) ...widget.inputFormatters!,
                if (widget.denySpaces)
                  FilteringTextInputFormatter.deny(
                    RegExp(r'\s'),
                  ),
              ],
              onChanged: widget.onChanged,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              enabled: widget.enabled,
              decoration: InputDecoration(
                isDense: true,
                hintStyle: widget.style.colored(
                  fieldPalette.hint,
                ),
                // TODO: Localization
                hintText: widget.hint,
                // hintText: widget.hint?.localize(context),
                contentPadding:
                    widget.padding ??
                    EdgeInsets.only(
                      top: 13,
                      bottom: 13,
                      left: widget.prefixIcon != null ? 0 : 16,
                      right: widget.suffixIcon != null ? 0 : 16,
                    ),
                border: border,
                enabled: widget.enabled,
                enabledBorder: border,
                errorBorder: border,
                focusedErrorBorder: border,
                disabledBorder: border,
                focusedBorder: border,
                filled: true,
                fillColor: fieldPalette.background,
                constraints: BoxConstraints(
                  minHeight: widget.minHeight,
                  maxHeight: widget.maxHeight,
                ),
                suffixIconConstraints: const BoxConstraints(),
                prefixIconConstraints: const BoxConstraints(),
                suffixIcon: widget.suffixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(0, 3, 8, 3),
                        child: UiIconButton(
                          widget.suffixIcon!,
                          color: fieldPalette.icon,
                          onTap: widget.onSuffixTap,
                        ),
                      )
                    : null,
                prefixIcon: widget.prefixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(8, 3, 0, 3),
                        child: UiIconButton(
                          widget.prefixIcon!,
                          color: fieldPalette.icon,
                          onTap: widget.onPrefixTap,
                        ),
                      )
                    : null,
              ),
            ),
            UiTextFieldError(widget.error ?? '', isVisible: widget.error != null && !widget.hideErrorText),
          ],
        ),
      ),
    );
  }
}

final class UiTextFieldError extends StatelessWidget {
  const UiTextFieldError(
    this.data, {
    required this.isVisible,
    super.key,
  });

  final bool isVisible;
  final String data;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const AppDuration.fast(),
      child: SizedBox(
        height: isVisible ? null : 0,
        child: Padding(
          padding: const AppPadding.smallT(),
          child: UiText(
            data,
            style: Styles.s12Medium,
            color: AppColors.red100,
          ),
        ),
      ),
    );
  }
}
