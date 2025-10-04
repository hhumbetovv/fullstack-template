import 'package:core_data/public.dart';
import 'package:core_domain/public.dart';

Future<Result<Data, Failure>> safeCall<Data>(
  Future<NetworkResponse<Data>> Function() requestCallback, {
  Future<void> Function(Data data)? handler,
}) async {
  final response = await safeRequest(requestCallback);
  if (response.isSuccess && response.data != null) {
    final data = response.data as Data;
    await handler?.call(data);
    return Success(data, action: response.action);
  }

  return response.mapToError(action: response.action);
}
