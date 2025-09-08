import 'package:core_data/public.dart';
import 'package:core_domain/public.dart';

Future<Result<Response, Failure>> safeMapperCall<Data, Response>(
  Future<NetworkResponse<Data>> Function() requestCallback, {
  required Response Function(Data data) mapper,
}) async {
  final response = await safeRequest(requestCallback);
  if (response.success && response.data != null) {
    final data = response.data as Data;

    return Success(mapper(data));
  }

  return response.mapToError();
}
