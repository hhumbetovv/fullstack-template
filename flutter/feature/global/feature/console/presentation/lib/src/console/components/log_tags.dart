import 'package:console_presentation/src/console/view_model.dart';
import 'package:core_presentation/exports.dart';
import 'package:flutter/material.dart';
import 'package:ui_components/public.dart';
import 'package:ui_foundation/public.dart';

final class LogTags extends StatelessWidget {
  const LogTags({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final selectedPalette = context.palette.button.primary;
    final unSelectedPalette = context.palette.button.outlined;

    return StateBuilder<ConsoleViewModel, ConsoleState>(
      depends: (state) => [state.tags, state.selectedTags],
      builder: (context, state, child) {
        if (state.tags.isEmpty) return const SizedBox.shrink();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 20, right: 12, bottom: 8),
          child: Row(
            children: state.tags.map((item) {
              final isSelected = state.selectedTags.contains(item);
              return Padding(
                padding: const AppPadding.smallR(),
                child: UIButton(
                  palette: isSelected ? selectedPalette : unSelectedPalette,
                  text: item,
                  removeSpacing: true,
                  height: AppDefaults.smallButtonHeight,
                  onClick: () {
                    ConsoleIntent.toggleTag(item).dispatch(context);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
