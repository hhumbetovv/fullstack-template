import 'package:common_presentation/public.dart';
import 'package:common_shared/public.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_components/public.dart';

final class UiText extends StatelessWidget {
  const UiText(
    this.data, {
    this.style,
    super.key,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textAlign,
    this.textScaler,
    this.args,
    this.onHighlightTap,
    this.highlightColor,
    this.color,
    this.semanticId,
  });

  final String data;
  final Map<String, dynamic>? args;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextAlign? textAlign;
  final TextScaler? textScaler;
  final ValueSetter<String>? onHighlightTap;
  final Color? highlightColor;
  final Color? color;
  final String? semanticId;

  @override
  Widget build(BuildContext context) {
    if (data.hasHighlight()) {
      return RichText(
        overflow: overflow ?? TextOverflow.clip,
        maxLines: maxLines,
        softWrap: softWrap ?? true,
        textAlign: textAlign ?? TextAlign.start,
        textScaler: textScaler ?? MediaQuery.textScalerOf(context),
        text: TextSpan(
          semanticsIdentifier: semanticId,
          semanticsLabel: semanticId,
          style: (style ?? Styles.kDefault).colored(color ?? context.palette.color.content),
          children: data.toHighlightedTextSpan(
            context,
            onHighlightTap,
            highlightColor,
          ),
        ),
      );
    }
    return Text(
      data,
      style: (style ?? Styles.kDefault).colored(color ?? context.palette.color.content),
      maxLines: maxLines,
      semanticsIdentifier: semanticId,
      semanticsLabel: semanticId,
      overflow: overflow,
      softWrap: softWrap,
      textAlign: textAlign,
      textScaler: textScaler,
    );
  }
}

extension on String {
  bool hasHighlight() {
    final firstIdentifier = indexOf('~');
    if (firstIdentifier == -1) return false;
    final lastIdentifier = lastIndexOf('~');
    return lastIdentifier > firstIdentifier;
  }

  List<TextSpan> toHighlightedTextSpan(
    BuildContext context,
    ValueSetter<String>? onTap,
    Color? color,
  ) {
    final highlightStyle = TextStyle(
      color: color ?? context.palette.color.primary,
    );
    final spans = split('~').mapIndexed((index, value) {
      if (value.isEmpty) return null;
      return TextSpan(
        text: value,
        style: index.isOdd ? highlightStyle : null,
        recognizer: index.isOdd && onTap != null
            ? (TapGestureRecognizer()
                ..onTap = () {
                  onTap(value);
                })
            : null,
      );
    });

    return spans.whereType<TextSpan>().toList();
  }
}
