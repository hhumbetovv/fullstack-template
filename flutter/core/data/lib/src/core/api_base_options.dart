import 'package:common_shared/environment.dart';
import 'package:dio/dio.dart';

final class ApiBaseOptions extends BaseOptions {
  ApiBaseOptions()
    : super(
        baseUrl: Environment.baseUrl,
        contentType: Headers.jsonContentType,
        connectTimeout: const Duration(seconds: 10),
      );
}
