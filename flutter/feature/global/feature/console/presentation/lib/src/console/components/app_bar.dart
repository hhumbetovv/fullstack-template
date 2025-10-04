import 'package:common_presentation/public.dart';
import 'package:console_presentation/src/console/view_model.dart';
import 'package:flutter/material.dart';
import 'package:ui_components/public.dart';

final class ConsoleAppBar extends StatelessWidget {
  const ConsoleAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return UiAppBar(
      showBackButton: true,
      title: 'Logs',
      trailing: Row(
        children: [
          const IconButton(
            onPressed: UiDebugger.toggleDebugPaint,
            icon: Icon(
              Icons.format_paint_outlined,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              const ConsoleIntent.refresh().dispatch(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              const ConsoleIntent.copyLogs().dispatch(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              const ConsoleIntent.shareLogs().dispatch(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              const ConsoleIntent.clearLogs().dispatch(context);
            },
          ),
        ],
      ),
    );
  }
}
