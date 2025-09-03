import 'package:json_annotation/json_annotation.dart';

part 'state_config.g.dart';

@JsonSerializable()
final class StateConfig {
  const StateConfig({
    required this.typeName,
    required this.isPrimitive,
  });

  factory StateConfig.fromJson(Map<String, dynamic> json) {
    return _$StateConfigFromJson(json);
  }

  final String? typeName;
  final bool isPrimitive;

  Map<String, dynamic> toJson() {
    return _$StateConfigToJson(this);
  }
}
