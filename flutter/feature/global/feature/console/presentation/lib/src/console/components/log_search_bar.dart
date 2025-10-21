import 'package:console_presentation/src/console/view_model.dart';
import 'package:flutter/material.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';

final class LogSearchBar extends StatefulWidget {
  const LogSearchBar({
    super.key,
  });

  @override
  State<LogSearchBar> createState() => _LogSearchBarState();
}

class _LogSearchBarState extends State<LogSearchBar> {
  final controller = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const AppPadding.macroH() + const AppPadding.smallB(),
      child: UiTextField(
        prefixIcon: AppIcons.search,
        suffixIcon: AppIcons.closeMD,
        hint: 'Search logs...',
        controller: controller,
        onChanged: (value) {
          ConsoleIntent.setQuery(value).dispatch(context);
        },
        onSuffixTap: () {
          const ConsoleIntent.setQuery('').dispatch(context);
          controller.clear();
        },
      ),
    );
  }
}
