import 'package:flutter/material.dart';

import 'dimens.dart';

class AppRadius extends BorderRadius {
  const AppRadius.zero() : super.only();

  const AppRadius.small() : super.all(const Radius.circular(AppDimens.small));

  const AppRadius.medium() : super.all(const Radius.circular(AppDimens.medium));

  const AppRadius.large() : super.all(const Radius.circular(AppDimens.large));

  const AppRadius.largeTop() : super.vertical(top: const Radius.circular(AppDimens.large));

  const AppRadius.largeBottom() : super.vertical(bottom: const Radius.circular(AppDimens.large));
}
