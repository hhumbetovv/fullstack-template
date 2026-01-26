import 'package:common_presentation/public.dart';
import 'package:console/presentation.dart';
import 'package:flutter/material.dart';
import 'package:ui_components/public.dart';

final class LogList extends StatelessWidget {
  const LogList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette.color;
    final logs = consoleSelect(context, (state) => state.logs);
    if (logs.isEmpty) {
      return ColoredBox(
        color: palette.background,
        child: Center(
          child: Text(
            'No Logs Available',
            style: Styles.s16Medium.colored(
              palette.caption,
            ),
          ),
        ),
      );
    }
    return ListBuilder(
      items: logs,
      shrinkWrap: true,
      itemBuilder: (item, _) {
        return LogItem(item: item);
      },
    );
  }
}
