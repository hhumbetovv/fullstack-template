// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'effect_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EffectConfig _$EffectConfigFromJson(Map<String, dynamic> json) => EffectConfig(
  view: json['view'] as String,
  viewModel: json['viewModel'] as String,
  method: MethodConfig.fromJson(json['method'] as Map<String, dynamic>),
);

Map<String, dynamic> _$EffectConfigToJson(EffectConfig instance) =>
    <String, dynamic>{
      'view': instance.view,
      'viewModel': instance.viewModel,
      'method': instance.method,
    };
