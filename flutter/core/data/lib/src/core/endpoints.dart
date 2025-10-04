import 'package:core_data/src/core/endpoint.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/http.dart';

class Endpoints {
  static final List<Endpoint> unprotected = [
    refresh,
    createOtp,
    confirmOtp,
  ];

  static final List<Endpoint> ignored = [];

  // TODO: Confirm Refresh Endpoint
  static final refresh = 'v1/auth/refresh'.post;
  static final createOtp = 'v1/auth/create-otp'.post;
  static final confirmOtp = 'v1/auth/confirm-otp'.post;

  static bool isProtected(RequestOptions options) {
    return !unprotected.containsMethod(options);
  }

  static bool isIgnored(RequestOptions options) {
    return ignored.containsMethod(options);
  }
}

extension on String {
  Endpoint get post => Endpoint(Method(HttpMethod.POST, this));
}

extension on List<Endpoint> {
  bool containsMethod(RequestOptions options) {
    final requestPath = options.path.split('?').first;
    return any((endpoint) => endpoint.matchesPath(requestPath, options.method));
  }
}
