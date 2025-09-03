// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'field_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FieldConfig _$FieldConfigFromJson(Map<String, dynamic> json) => FieldConfig(
  name: json['name'] as String,
  type: json['type'] as String,
  isNullable: json['isNullable'] as bool,
  isRequired: json['isRequired'] as bool,
  defaultValue: json['defaultValue'] as String?,
);

Map<String, dynamic> _$FieldConfigToJson(FieldConfig instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'isNullable': instance.isNullable,
      'isRequired': instance.isRequired,
      'defaultValue': instance.defaultValue,
    };
