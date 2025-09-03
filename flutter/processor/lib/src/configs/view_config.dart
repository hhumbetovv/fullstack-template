import 'package:json_annotation/json_annotation.dart';
import 'package:processor/src/configs/effect_config.dart';

part 'view_config.g.dart';

@JsonSerializable()
final class ViewConfig {
  const ViewConfig({
    required this.name,
    required this.isStateful,
    required this.customFactory,
    required this.effects,
  });

  factory ViewConfig.fromJson(Map<String, dynamic> json) {
    return _$ViewConfigFromJson(json);
  }

  final String name;
  final bool isStateful;
  final bool customFactory;
  final List<EffectConfig> effects;

  Map<String, dynamic> toJson() {
    return _$ViewConfigToJson(this);
  }
}
