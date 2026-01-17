import 'package:common_shared/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';

final class LogDetailsSheet extends StatelessWidget {
  const LogDetailsSheet({
    required this.item,
    super.key,
  });

  final LogEntry item;

  @override
  Widget build(BuildContext context) {
    final message = item.message.split('\n');
    final palette = context.palette;
    return UiBottomSheet(
      title: message[0],
      titleStyle: Styles.s20Medium,
      titleColor: item.color.toHex() ?? palette.color.content,
      crossAxisAlignment: CrossAxisAlignment.start,
      subTitle: Console.now(null, item.timestamp),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: SelectableText(
                message.skip(1).join('\n'),
                textAlign: TextAlign.start,
                style: Styles.s16Medium,
              ),
            ),
            const AppSpacing.smallV(),
            Row(
              spacing: AppDimens.small,
              children: [
                Expanded(
                  child: UIButton(
                    onClick: () {
                      Clipboard.setData(ClipboardData(text: item.message));
                      Navigator.pop(context);
                      SnackBarManager.showInfo('Log copied to clipboard');
                    },
                    palette: palette.button.primary,
                    text: 'Copy',
                  ),
                ),
                Expanded(
                  child: UIButton(
                    onClick: () {
                      Navigator.maybePop(context);
                    },
                    palette: palette.button.outlined,
                    text: 'Close',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
