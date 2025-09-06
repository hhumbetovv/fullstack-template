import 'package:auto_route/auto_route.dart';
import 'package:core_presentation/widgets.dart';
import 'package:flutter/material.dart';
import 'package:processor/processor.dart';

import 'view_model.dart';

part 'view.g.dart';

@view
@RoutePage()
final class FirstView extends _FirstView {
  const FirstView({
    super.key,
  });

  @override
  Widget buildView(BuildContext context) {
    return Container();
  }
}
