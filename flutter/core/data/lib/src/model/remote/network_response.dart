import 'package:core_domain/public.dart';
import 'package:json_annotation/json_annotation.dart';

part 'network_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class NetworkResponse<T> {
  NetworkResponse({
    this.isSuccess = true,
    this.message,
    this.action,
    this.data,
    this.errors = const [],
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
  final bool isSuccess;

  @JsonKey(name: 'message')
  final String? message;

  @JsonKey(name: 'action')
  final String? action;

  @JsonKey(name: 'data')
  final T? data;

  @JsonKey(name: 'errors')
  final List<String?> errors;

  Error<Data, Failure> mapToError<Data>({String? action}) {
    return Error(
      Failure(
        message: message,
      ),
      action: action,
    );
  }

  @override
  String toString() {
    return message ?? 'Unknown Error';
  }
}
