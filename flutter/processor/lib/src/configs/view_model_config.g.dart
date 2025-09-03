// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'view_model_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ViewModelConfig _$ViewModelConfigFromJson(Map<String, dynamic> json) =>
    ViewModelConfig(
      name: json['name'] as String,
      state: StateConfig.fromJson(json['state'] as Map<String, dynamic>),
      effects: (json['effects'] as List<dynamic>)
          .map((e) => EffectConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
      intents: (json['intents'] as List<dynamic>)
          .map((e) => MethodConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ViewModelConfigToJson(ViewModelConfig instance) =>
    <String, dynamic>{
      'name': instance.name,
      'state': instance.state,
      'effects': instance.effects,
      'intents': instance.intents,
    };
