import 'package:json_annotation/json_annotation.dart';
import 'package:processor/src/configs/effect_config.dart';
import 'package:processor/src/configs/method_config.dart';
import 'package:processor/src/configs/state_config.dart';

part 'view_model_config.g.dart';

@JsonSerializable()
class ViewModelConfig {
  const ViewModelConfig({
    required this.name,
    required this.state,
    required this.effects,
    required this.intents,
  });

  factory ViewModelConfig.fromJson(Map<String, dynamic> json) {
    return _$ViewModelConfigFromJson(json);
  }

  final String name;
  final StateConfig state;
  final List<EffectConfig> effects;
  final List<MethodConfig> intents;

  Map<String, dynamic> toJson() {
    return _$ViewModelConfigToJson(this);
  }
}
