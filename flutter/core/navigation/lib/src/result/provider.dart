import 'package:core_navigation/src/result/view_model.dart';
import 'package:core_presentation/exports.dart';
import 'package:flutter/widgets.dart';
import 'package:processor/public.dart';

part 'provider.g.dart';

@provider
final class ResultProvider extends _ResultProvider {
  const ResultProvider({
    super.key,
    super.child,
  });
}
