import 'package:flutter/rendering.dart';

import 'dimens.dart';

class AppPadding extends EdgeInsets {
  const AppPadding(super.value) : super.all();

  const AppPadding.h(double value) : super.symmetric(horizontal: value);
  const AppPadding.v(double value) : super.symmetric(vertical: value);
  const AppPadding.l(double value) : super.only(left: value);
  const AppPadding.t(double value) : super.only(top: value);
  const AppPadding.r(double value) : super.only(right: value);
  const AppPadding.b(double value) : super.only(left: value);

  const AppPadding.zero() : super.only();

  const AppPadding.base() : super.symmetric(horizontal: AppDimens.macro, vertical: AppDimens.large);
  const AppPadding.baseH() : super.symmetric(horizontal: AppDimens.macro);
  const AppPadding.baseV() : super.symmetric(vertical: AppDimens.large);

  const AppPadding.max() : super.all(AppDimens.max);
  const AppPadding.maxV() : super.symmetric(vertical: AppDimens.max);
  const AppPadding.maxH() : super.symmetric(horizontal: AppDimens.max);
  const AppPadding.maxT() : super.only(top: AppDimens.max);
  const AppPadding.maxB() : super.only(bottom: AppDimens.max);
  const AppPadding.maxL() : super.only(left: AppDimens.max);
  const AppPadding.maxR() : super.only(right: AppDimens.max);

  const AppPadding.macro() : super.all(AppDimens.macro);
  const AppPadding.macroV() : super.symmetric(vertical: AppDimens.macro);
  const AppPadding.macroH() : super.symmetric(horizontal: AppDimens.macro);
  const AppPadding.macroT() : super.only(top: AppDimens.macro);
  const AppPadding.macroB() : super.only(bottom: AppDimens.macro);
  const AppPadding.macroL() : super.only(left: AppDimens.macro);
  const AppPadding.macroR() : super.only(right: AppDimens.macro);

  const AppPadding.large() : super.all(AppDimens.large);
  const AppPadding.largeV() : super.symmetric(vertical: AppDimens.large);
  const AppPadding.largeH() : super.symmetric(horizontal: AppDimens.large);
  const AppPadding.largeT() : super.only(top: AppDimens.large);
  const AppPadding.largeB() : super.only(bottom: AppDimens.large);
  const AppPadding.largeL() : super.only(left: AppDimens.large);
  const AppPadding.largeR() : super.only(right: AppDimens.large);

  const AppPadding.medium() : super.all(AppDimens.medium);
  const AppPadding.mediumV() : super.symmetric(vertical: AppDimens.medium);
  const AppPadding.mediumH() : super.symmetric(horizontal: AppDimens.medium);
  const AppPadding.mediumT() : super.only(top: AppDimens.medium);
  const AppPadding.mediumB() : super.only(bottom: AppDimens.medium);
  const AppPadding.mediumL() : super.only(left: AppDimens.medium);
  const AppPadding.mediumR() : super.only(right: AppDimens.medium);

  const AppPadding.small() : super.all(AppDimens.small);
  const AppPadding.smallV() : super.symmetric(vertical: AppDimens.small);
  const AppPadding.smallH() : super.symmetric(horizontal: AppDimens.small);
  const AppPadding.smallT() : super.only(top: AppDimens.small);
  const AppPadding.smallB() : super.only(bottom: AppDimens.small);
  const AppPadding.smallL() : super.only(left: AppDimens.small);
  const AppPadding.smallR() : super.only(right: AppDimens.small);

  const AppPadding.micro() : super.all(AppDimens.micro);
  const AppPadding.microV() : super.symmetric(vertical: AppDimens.micro);
  const AppPadding.microH() : super.symmetric(horizontal: AppDimens.micro);
  const AppPadding.microT() : super.only(top: AppDimens.micro);
  const AppPadding.microB() : super.only(bottom: AppDimens.micro);
  const AppPadding.microL() : super.only(left: AppDimens.micro);
  const AppPadding.microR() : super.only(right: AppDimens.micro);

  const AppPadding.min() : super.all(AppDimens.min);
  const AppPadding.minV() : super.symmetric(vertical: AppDimens.min);
  const AppPadding.minH() : super.symmetric(horizontal: AppDimens.min);
  const AppPadding.minT() : super.only(top: AppDimens.min);
  const AppPadding.minB() : super.only(bottom: AppDimens.min);
  const AppPadding.minL() : super.only(left: AppDimens.min);
  const AppPadding.minR() : super.only(right: AppDimens.min);
}
