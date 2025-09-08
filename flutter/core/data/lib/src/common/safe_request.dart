import 'dart:async';
import 'dart:convert';

import 'package:common_shared/public.dart';
import 'package:core_data/src/model/network_response.dart';
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
      if (dioError.response?.data != null) {
        final json = dioError.response?.data! as Map<String, dynamic>;
        return NetworkResponse.fromJson(json, (_) => null);
      } else {
        return NetworkResponse(success: false, message: dioError.error.toString());
      }
    } on Exception catch (error) {
      Console.firebaseRecordError(
        dioError,
        dioError.stackTrace,
        reason: 'Dio Error parse Failed',
      );
      return NetworkResponse(
        success: false,
        message: error.toString(),
      );
    }
  } on Exception catch (error) {
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
      success: false,
      message: error.toString(),
    );
  }
}
