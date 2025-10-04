import 'dart:async';
import 'dart:io';

import 'package:common_shared/public.dart';
import 'package:core_data/public.dart';
import 'package:core_data/src/datasource/local/secure_storage/secure_storage.dart';
import 'package:core_data/src/datasource/local/secure_storage/secure_storage_extensions.dart';
import 'package:core_data/src/datasource/local/session_local_service.dart';
import 'package:core_domain/public.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor();

  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  Future<String> get _accessToken async {
    return await SecureStorage.accessToken.read ?? '';
  }

  Future<bool> get _accessIsExpired async {
    final exp = await SecureStorage.accessExpiration.read;
    if (exp.isNullOrEmpty()) return true;
    final expDate = int.parse(exp ?? '0').toEntity();
    return DateTime.now().isAfter(expDate);
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (Endpoints.isProtected(options)) {
      String? accessToken = await _accessToken;

      if (accessToken.isEmpty || await _accessIsExpired) {
        accessToken = await _refreshToken();

        if (accessToken == null && !Endpoints.isIgnored(options)) {
          return handler.reject(await getSessionError(options));
        }
      }
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    super.onRequest(options, handler);
  }

  Future<String?> _refreshToken() async {
    if (_isRefreshing) {
      return _refreshCompleter!.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final result = await GetIt.I<SessionRepository>().refresh();

      if (result.isSuccess()) {
        final newToken = await _accessToken;

        _refreshCompleter!.complete(newToken);

        _isRefreshing = false;
        _refreshCompleter = null;

        return newToken;
      } else {
        _refreshCompleter!.complete(null);
        _isRefreshing = false;
        _refreshCompleter = null;
        return null;
      }
    } catch (e) {
      _refreshCompleter!.completeError(e);
      _isRefreshing = false;
      _refreshCompleter = null;
      rethrow;
    }
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    try {
      if (isAccessError(err)) {
        final token = await _refreshToken();

        if (token != null) {
          final retryOptions = err.requestOptions..headers['Authorization'] = 'Bearer $token';

          try {
            final response = await GetIt.I<Dio>().fetch<dynamic>(retryOptions);
            return handler.resolve(response);
          } on DioException catch (e) {
            return handler.next(e);
          }
        } else {
          return handler.next(await getSessionError(err.requestOptions));
        }
      } else if (isRefreshError(err)) {
        return handler.next(err);
      }
      return handler.next(err);
    } on Exception catch (_) {
      return handler.next(err);
    }
  }

  bool isAccessError(DioException error) {
    if (error.response?.statusCode != HttpStatus.unauthorized) return false;
    return Endpoints.isProtected(error.requestOptions);
  }

  bool isRefreshError(DioException error) {
    if (error.response?.statusCode != HttpStatus.unauthorized) return false;
    return Endpoints.refresh.matchesRequest(error.requestOptions);
  }
}

Future<DioException> getSessionError(RequestOptions options) async {
  final data = NetworkResponse<dynamic>(
    isSuccess: false,
    // TODO: Extract Actions to common use
    action: 'LOGOUT',
  );

  final json = data.toJson((_) => null);

  await GetIt.I<SessionLocalService>().removeSession();

  return DioException(
    requestOptions: options,
    response: Response(
      requestOptions: options,
      data: json,
      statusCode: HttpStatus.unauthorized,
    ),
  );
}
