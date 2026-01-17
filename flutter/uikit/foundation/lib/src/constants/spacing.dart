import 'package:flutter/widgets.dart';

import 'dimens.dart';

class AppSpacing extends SizedBox {
  const AppSpacing.maxV({super.key}) : super(height: AppDimens.max);
  const AppSpacing.macroV({super.key}) : super(height: AppDimens.macro);
  const AppSpacing.largeV({super.key}) : super(height: AppDimens.large);
  const AppSpacing.mediumV({super.key}) : super(height: AppDimens.medium);
  const AppSpacing.smallV({super.key}) : super(height: AppDimens.small);
  const AppSpacing.microV({super.key}) : super(height: AppDimens.micro);
  const AppSpacing.minV({super.key}) : super(height: AppDimens.min);

  const AppSpacing.maxH({super.key}) : super(width: AppDimens.max);
  const AppSpacing.macroH({super.key}) : super(width: AppDimens.macro);
  const AppSpacing.largeH({super.key}) : super(width: AppDimens.large);
  const AppSpacing.mediumH({super.key}) : super(width: AppDimens.medium);
  const AppSpacing.smallH({super.key}) : super(width: AppDimens.small);
  const AppSpacing.microH({super.key}) : super(width: AppDimens.micro);
  const AppSpacing.minH({super.key}) : super(width: AppDimens.min);
}
