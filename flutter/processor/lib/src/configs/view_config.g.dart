// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'view_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ViewConfig _$ViewConfigFromJson(Map<String, dynamic> json) => ViewConfig(
  name: json['name'] as String,
  isStateful: json['isStateful'] as bool,
  customFactory: json['customFactory'] as bool,
  effects: (json['effects'] as List<dynamic>)
      .map((e) => EffectConfig.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ViewConfigToJson(ViewConfig instance) =>
    <String, dynamic>{
      'name': instance.name,
      'isStateful': instance.isStateful,
      'customFactory': instance.customFactory,
      'effects': instance.effects,
    };
