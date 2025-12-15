import 'dart:async';
import 'dart:convert';

import 'package:common_shared/public.dart';
import 'package:core_data/src/model/remote/network_response.dart';
import 'package:dio/dio.dart';

Future<NetworkResponse<Data?>> safeRequest<Data>(
  Future<NetworkResponse<Data>> Function() callBack,
) async {
  try {
    return await callBack();
  } on DioException catch (dioError) {
    final errorLog =
        '🔴 DIO NETWORK EXCEPTION | ${dioError.type}\n'
        'URL: ${dioError.requestOptions.uri}\n'
        'METHOD: ${dioError.requestOptions.method.toUpperCase()}\n'
        'STATUS CODE: ${dioError.response?.statusCode ?? 'N/A'}\n'
        'REQUEST DATA: ${dioError.requestOptions.data != null ? jsonEncode(dioError.requestOptions.data) : 'No Data'}\n'
        'HEADERS: ${dioError.requestOptions.headers}\n'
        'RESPONSE: ${dioError.response?.data != null ? jsonEncode(dioError.response?.data) : 'No Response'}\n'
        'ERROR MESSAGE: ${dioError.message ?? 'Unknown Error'}\n'
        'TIMESTAMP: ${DateTime.now().toIso8601String()}';

    Console.firebaseLog(errorLog);
    Console.firebaseRecordError(
      dioError,
      dioError.stackTrace,
      reason: 'Dio Request Failed',
    );
    try {
      final data = dioError.response?.data;
      final isServerError = (dioError.response?.statusCode ?? 0) >= 500;

      if (data != null && data is Map<String, dynamic> && !isServerError) {
        final json = data;
        return NetworkResponse.fromJson(json, (_) => null);
      } else {
        final String message;
        if (isServerError) {
          message = 'Unknown Error occurred';
        } else {
          message = dioError.error.toString();
        }
        return NetworkResponse(isSuccess: false, message: message);
      }
    } on Object catch (error) {
      Console.firebaseRecordError(
        dioError,
        dioError.stackTrace,
        reason: 'Dio Error parse Failed',
      );
      return NetworkResponse(
        isSuccess: false,
        message: error.toString(),
      );
    }
  } on Object catch (error) {
    final errorLog =
        '📶 NETWORK EXCEPTION\n'
        'TYPE: ${error.runtimeType}\n'
        'CALLBACK: $callBack\n'
        'ERROR: $error\n'
        'TIMESTAMP: ${DateTime.now().toIso8601String()}';

    Console.firebaseLog(errorLog);
    Console.firebaseRecordError(
      error,
      StackTrace.current,
      reason: 'Dio Request Failed',
    );

    return NetworkResponse(
      isSuccess: false,
      message: error.toString(),
    );
  }
}
