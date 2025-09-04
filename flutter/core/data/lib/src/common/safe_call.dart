import 'package:core_data/common.dart';
import 'package:core_data/src/model/network_response.dart';
import 'package:core_domain/entity.dart';
import 'package:core_domain/result.dart';

Future<Result<Data, Failure>> safeCall<Data>(
  Future<NetworkResponse<Data>> Function() requestCallback, {
  Future<void> Function(Data data)? handler,
}) async {
  final response = await safeRequest(requestCallback);
  if (response.success && response.data != null) {
    final data = response.data as Data;
    await handler?.call(data);
    return Success(data);
  }

  return response.mapToError();
}
