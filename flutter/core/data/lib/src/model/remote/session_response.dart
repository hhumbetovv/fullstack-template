import 'package:json_annotation/json_annotation.dart';

part 'session_response.g.dart';

@JsonSerializable(createToJson: false)
class SessionResponse {
  const SessionResponse({
    this.refreshToken,
    this.accessToken,
    this.refreshExpiration,
    this.accessExpiration,
  });

  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    return _$SessionResponseFromJson(json);
  }

  final String? refreshToken;
  final String? accessToken;
  final int? refreshExpiration;
  final int? accessExpiration;

  bool get isValid {
    return refreshToken != null && accessToken != null && refreshExpiration != null && accessExpiration != null;
  }
}
