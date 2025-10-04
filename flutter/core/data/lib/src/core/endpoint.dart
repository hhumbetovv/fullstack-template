import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

class Endpoint {
  Endpoint(Method method)
    : method = method.method,
      pattern = RegExp(
        '^${method.path.replaceAllMapped(
          RegExp(r'\{([^}]+)\}'),
          (match) => '([^/]+)',
        )}\$',
      );

  final String method;
  final RegExp pattern;

  bool matchesRequest(RequestOptions options) {
    if (options.method != method) return false;
    final requestPath = options.path.split('?').first;
    return pattern.hasMatch(requestPath);
  }

  bool matchesPath(String path, String method) {
    if (method != this.method) return false;
    return pattern.hasMatch(path);
  }
}
