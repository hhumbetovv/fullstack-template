import 'package:json_annotation/json_annotation.dart';

part 'session_request.g.dart';

@JsonSerializable(createFactory: false)
class SessionRequest {
  const SessionRequest({
    required this.refreshToken,
  });

  Map<String, dynamic> toJson() {
    return _$SessionRequestToJson(this);
  }

  @JsonKey(name: 'refreshToken')
  final String refreshToken;
}
