import 'package:json_annotation/json_annotation.dart';

part 'field_config.g.dart';

@JsonSerializable()
final class FieldConfig {
  FieldConfig({
    required this.name,
    required this.type,
    required this.isNullable,
    required this.isRequired,
    required this.defaultValue,
  });

  factory FieldConfig.fromJson(Map<String, dynamic> json) {
    return _$FieldConfigFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$FieldConfigToJson(this);
  }

  final String name;
  final String type;
  final bool isNullable;
  final bool isRequired;
  final String? defaultValue;
}
