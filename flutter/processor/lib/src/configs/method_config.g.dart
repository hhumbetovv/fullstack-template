// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'method_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MethodConfig _$MethodConfigFromJson(Map<String, dynamic> json) => MethodConfig(
  name: json['name'] as String,
  params: (json['params'] as List<dynamic>)
      .map((e) => ParamConfig.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$MethodConfigToJson(MethodConfig instance) =>
    <String, dynamic>{'name': instance.name, 'params': instance.params};
