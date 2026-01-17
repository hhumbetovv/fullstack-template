import 'package:core_presentation/exports.dart';
import 'package:flutter/material.dart';
import 'package:processor/processor.dart';

import 'view_model.dart';

part 'view.g.dart';

@view
final class FirstView extends _FirstView {
  const FirstView({
    super.key,
  });

  @override
  Widget buildView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            const FirstIntent.method().dispatch(context);
          },
          child: Text(
            firstSelect(
              context,
              (state) => state.value.toString(),
            ),
          ),
        ),
      ),
    );
  }
}
