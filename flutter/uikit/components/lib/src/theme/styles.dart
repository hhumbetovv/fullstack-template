import 'package:flutter/material.dart';

sealed class Styles {
  static const defaultHeight = 1.17;

  // ! 12 SP
  static const s12Medium = TextStyle(
    height: defaultHeight,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  // ! 14 SP
  static const s14Regular = TextStyle(
    height: defaultHeight,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const s14Medium = TextStyle(
    height: defaultHeight,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  static const s14Semibold = TextStyle(
    height: defaultHeight,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  // ! 16 SP
  static const s16Regular = TextStyle(
    height: defaultHeight,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static const s16Medium = TextStyle(
    height: defaultHeight,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  static const s16Semibold = TextStyle(
    height: defaultHeight,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // ! 20 SP
  static const s20Medium = TextStyle(
    height: defaultHeight,
    fontSize: 20,
    fontWeight: FontWeight.w500,
  );
  static const s20Semibold = TextStyle(
    height: defaultHeight,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  // ? Product
  static const kDefault = s14Medium;
  static const bottomSheetTitle = s16Medium;
  static const bottomSheetSubTitle = s14Medium;
  static const button = s14Semibold;
  static const textField = s14Regular;
  static const iconButton = s14Medium;
}
