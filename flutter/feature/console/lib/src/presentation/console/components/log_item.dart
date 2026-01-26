import 'package:common_presentation/public.dart';
import 'package:common_shared/public.dart';
import 'package:flutter/material.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';

import 'log_details_sheet.dart';

class LogItem extends StatelessWidget {
  const LogItem({
    required this.item,
    super.key,
  });

  final LogEntry item;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = item.color.toHex() ?? palette.color.content;
    return Card(
      color: palette.color.background,
      shape: const Border(),
      shadowColor: color,
      elevation: 3,
      margin: const AppPadding.microV(),
      child: Padding(
        padding: const AppPadding.baseH(),
        child: Clickable(
          onTap: () {
            BottomSheetManager.push<void>(
              context: context,
              content: LogDetailsSheet(item: item),
            );
          },
          child: Padding(
            padding: const AppPadding.medium(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.message.length > 100
                            ? '${item.message.substring(0, 100)}...'
                            : item.message.replaceRange(item.message.length - 1, item.message.length, ''),
                        style: Styles.s14Medium,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                Text(
                  Console.now('HH:mm', item.timestamp),
                  style: Styles.s12Medium.colored(
                    color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
