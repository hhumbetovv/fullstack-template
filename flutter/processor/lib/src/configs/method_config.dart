import 'package:json_annotation/json_annotation.dart';
import 'package:processor/src/configs/param_config.dart';

part 'method_config.g.dart';

@JsonSerializable()
final class MethodConfig {
  const MethodConfig({
    required this.name,
    required this.params,
  });

  factory MethodConfig.fromJson(Map<String, dynamic> json) {
    return _$MethodConfigFromJson(json);
  }

  final String name;
  final List<ParamConfig> params;

  Map<String, dynamic> toJson() {
    return _$MethodConfigToJson(this);
  }
}
