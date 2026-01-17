import 'package:core_data/src/model/remote/network_response.dart';
import 'package:core_data/src/model/remote/session_request.dart';
import 'package:core_data/src/model/remote/session_response.dart';
import 'package:core_domain/public.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

part 'session_api.g.dart';

@RestApi()
@injectable
abstract class SessionApi {
  @factoryMethod
  factory SessionApi(Dio dio) => _SessionApi(dio);

  @POST('v1/auth/refresh')
  Future<NetworkResponse<SessionResponse>> refresh({
    @Body() required SessionRequest body,
  });

  @POST('v1/auth/logout')
  Future<NetworkResponse<Unit>> logout({
    @Body() required SessionRequest body,
  });
}
