import 'package:core_data/public.dart';
import 'package:core_domain/public.dart';

AsyncResult<Unit> safeUnitCall<Data>(
  Future<NetworkResponse<Data>> Function() requestCallback, {
  Future<void> Function(Data data, Action? action)? handler,
}) async {
  final response = await safeRequest(requestCallback);
  if (response.isSuccess) {
    if (response.data != null) {
      await handler?.call(response.data as Data, response.action?.toEntity());
    }
    return Success.unit(action: response.action?.toEntity());
  }
  return response.mapToError(action: response.action?.toEntity());
}
