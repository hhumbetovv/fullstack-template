import 'package:core_domain/public.dart';
import 'package:json_annotation/json_annotation.dart';

part 'network_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class NetworkResponse<T> {
  NetworkResponse({
    this.success = true,
    this.message,
    this.data,
  });

  factory NetworkResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) {
    return _$NetworkResponseFromJson(json, fromJsonT);
  }

  Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
    return _$NetworkResponseToJson(this, toJsonT);
  }

  @JsonKey(name: 'success')
  final bool success;

  @JsonKey(name: 'message')
  final String? message;

  @JsonKey(name: 'data')
  final T? data;

  Error<Data, Failure> mapToError<Data>() {
    return Error(
      Failure(
        message: message,
      ),
    );
  }

  @override
  String toString() {
    return message ?? 'Unknown Error';
  }
}
