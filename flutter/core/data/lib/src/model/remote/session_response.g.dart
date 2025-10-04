// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionResponse _$SessionResponseFromJson(Map<String, dynamic> json) =>
    SessionResponse(
      refreshToken: json['refreshToken'] as String?,
      accessToken: json['accessToken'] as String?,
      refreshExpiration: (json['refreshExpiration'] as num?)?.toInt(),
      accessExpiration: (json['accessExpiration'] as num?)?.toInt(),
    );
