import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

extension DartTypeExt on DartType {
  bool get isNullable {
    return nullabilitySuffix == NullabilitySuffix.question;
  }

  bool get isPrimitive {
    return isDartCoreInt || isDartCoreDouble || isDartCoreBool || isDartCoreString || isDartCoreNum;
  }
}
