import 'package:dio/dio.dart';

class FormInterceptor extends Interceptor {
  const FormInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final requestData = options.data;

    if (requestData is FormData && requestData.isFinalized) {
      return handler.next(
        options.copyWith(data: requestData.clone()),
      );
    }
    super.onRequest(options, handler);
  }
}
