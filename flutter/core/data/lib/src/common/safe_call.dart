import 'package:core_data/public.dart';
import 'package:core_domain/public.dart';

AsyncResult<Data> safeCall<Data>(
  Future<NetworkResponse<Data>> Function() requestCallback, {
  Future<void> Function(Data data)? handler,
}) async {
  final response = await safeRequest(requestCallback);
  if (response.isSuccess && response.data != null) {
    final data = response.data as Data;
    await handler?.call(data);
    return Success(data, action: response.action?.toEntity());
  }

  return response.mapToError(action: response.action?.toEntity());
}
