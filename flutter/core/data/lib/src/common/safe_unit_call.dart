import 'package:core_data/public.dart';
import 'package:core_domain/public.dart';

AsyncResult<Unit> safeUnitCall<Data>(
  Future<NetworkResponse<Data>> Function() requestCallback, {
  Future<void> Function(Data data)? handler,
}) async {
  final response = await safeRequest(requestCallback);
  if (response.success) {
    if (response.data != null) {
      await handler?.call(response.data as Data);
    }
    return Success.unit();
  }
  return response.mapToError();
}
