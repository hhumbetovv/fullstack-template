// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DataConfig _$DataConfigFromJson(Map<String, dynamic> json) => DataConfig(
  name: json['name'] as String,
  isFactory: json['isFactory'] as bool,
  fields: (json['fields'] as List<dynamic>)
      .map((e) => FieldConfig.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DataConfigToJson(DataConfig instance) =>
    <String, dynamic>{
      'name': instance.name,
      'isFactory': instance.isFactory,
      'fields': instance.fields,
    };
