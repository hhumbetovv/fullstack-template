import 'dart:convert';

import 'package:common_shared/public.dart';
import 'package:dio/dio.dart';

class LoggerInterceptor extends Interceptor {
  final encoder = const JsonEncoder.withIndent('  ');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    Console.log(
      '🚀 HTTP REQUEST | ${options.method.toUpperCase()}\n'
          'URL: ${options.uri}\n'
          '${_getHeaders(options.headers)}'
          '${_getBody(options.data)}',
      AnsiColors.amber,
      'Http',
    );
    options.extra['stopwatch'] = Stopwatch()..start();
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final stopwatch = response.requestOptions.extra['stopwatch'] as Stopwatch?;
    stopwatch?.stop();
    Console.log(
      '✅ HTTP RESPONSE | ${stopwatch?.elapsedMilliseconds}ms\n'
          'URL: ${response.requestOptions.uri}\n'
          '${_getStatus(response)}'
          '${_getHeaders(response.headers.map)}'
          '${_getBody(response.data)}',
      AnsiColors.green,
      'Http',
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final stopwatch = err.requestOptions.extra['stopwatch'] as Stopwatch?;
    stopwatch?.stop();
    Console.log(
      '❌ HTTP ERROR | ${stopwatch?.elapsedMilliseconds}ms\n'
          'URL: ${err.requestOptions.uri}\n'
          '${_getStatus(err.response)}'
          '${_getHeaders(err.response?.headers.map)}'
          '${_getBody(err.response?.data)}'
          'MESSAGE: ${err.message ?? 'unknown'}',
      AnsiColors.red,
      'Http',
    );
    super.onError(err, handler);
  }

  String _getBody(
    dynamic data,
  ) {
    if (data == null) {
      return '';
    }

    if (data is FormData) {
      final buffer = StringBuffer()..writeln('BODY: FormData');

      if (data.fields.isNotEmpty) {
        buffer.writeln('FIELDS:');
      }
      for (final field in data.fields) {
        buffer.writeln('   ${field.key}: ${field.value}');
      }

      if (data.fields.isNotEmpty) {
        buffer.writeln('FILES:');
      }
      for (final file in data.files) {
        final key = file.key;
        final multipartFile = file.value;
        buffer.writeln('  $key -> filename: ${multipartFile.filename}, path: ${multipartFile.filename ?? "unknown"}');
      }

      return buffer.toString();
    }

    try {
      final jsonString = encoder.convert(data);

      return 'BODY: $jsonString\n';
    } on Exception catch (e) {
      return 'BODY FAIL: $e\n';
    }
  }

  String _getHeaders(
    Map<dynamic, dynamic>? headers,
  ) {
    if (headers == null) return '';

    final loggableKeys = ['content-type', 'accept', 'user-agent', 'authorization', 'x-request-id'];

    return headers.entries.fold(
      'HEADERS:\n',
      (previousValue, entry) {
        final keyString = entry.key.toString().toLowerCase();
        if (loggableKeys.contains(keyString)) {
          if (keyString == 'authorization') {
            final valueStr = entry.value.toString();
            final anonymized = valueStr.length > 10
                ? '${valueStr.substring(0, 12)}...${valueStr.substring(valueStr.length - 5)}'
                : '***';
            return '  ${entry.key}: $anonymized\n';
          } else {
            return '  ${entry.key}: ${entry.value}\n';
          }
        }
        return '';
      },
    );
  }

  String _getStatus(Response<dynamic>? response) {
    if (response?.statusCode == null && (response?.statusMessage?.isEmpty ?? true)) {
      return '';
    }
    return 'STATUS: ${response?.statusCode} ${response?.statusMessage?.toUpperCase()}\n';
  }
}
