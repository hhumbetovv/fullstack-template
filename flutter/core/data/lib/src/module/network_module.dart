import 'package:common_shared/utils.dart';
import 'package:core_data/src/core/api_base_options.dart';
import 'package:core_data/src/interceptors/form_interceptor.dart';
import 'package:core_data/src/interceptors/logger_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@module
class NetworkModule {
  @singleton
  Dio get dio {
    return Dio()
      ..interceptors.addAll([
        const FormInterceptor(),
        // JwtInterceptor(),
        if (Console.isEnabled) LoggerInterceptor(),
      ])
      ..options = ApiBaseOptions();
  }
}
