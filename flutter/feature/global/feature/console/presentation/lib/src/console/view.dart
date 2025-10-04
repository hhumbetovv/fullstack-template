import 'package:auto_route/auto_route.dart';
import 'package:console_presentation/src/console/components/app_bar.dart';
import 'package:console_presentation/src/console/components/log_list.dart';
import 'package:console_presentation/src/console/components/log_search_bar.dart';
import 'package:console_presentation/src/console/components/log_tags.dart';
import 'package:core_presentation/exports.dart';
import 'package:flutter/material.dart';
import 'package:processor/public.dart';
import 'package:ui_components/public.dart';

import 'view_model.dart';

part 'view.g.dart';

@view
@RoutePage()
final class ConsoleView extends _ConsoleView {
  const ConsoleView({
    super.key,
  });

  @override
  Widget buildView(BuildContext context) {
    return SafeArea(
      child: ColoredBox(
        color: context.palette.color.background,
        child: const Collapsible(
          appBar: ConsoleAppBar(),
          header: LogSearchBar(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LogTags(),
              Expanded(child: LogList()),
            ],
          ),
        ),
      ),
    );
  }
}
