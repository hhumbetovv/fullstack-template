import 'package:core_data/src/common/safe_unit_call.dart';
import 'package:core_data/src/datasource/local/secure_storage/secure_storage.dart';
import 'package:core_data/src/datasource/local/secure_storage/secure_storage_extensions.dart';
import 'package:core_data/src/datasource/local/session_local_service.dart';
import 'package:core_data/src/datasource/remote/session_api.dart';
import 'package:core_data/src/model/remote/session_request.dart';
import 'package:core_domain/public.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: SessionRepository)
class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl(this._sessionLocalService, this._sessionApi);

  final SessionLocalService _sessionLocalService;
  final SessionApi _sessionApi;

  @override
  AsyncResult<Unit> logout() async {
    final refreshToken = await SecureStorage.refreshToken.read;

    final Result<Unit, Failure> response;
    if (refreshToken != null) {
      response = await safeUnitCall(() {
        return _sessionApi.logout(
          body: SessionRequest(refreshToken: refreshToken),
        );
      });
    } else {
      response = Success.unit();
    }

    await _sessionLocalService.removeSession();

    return response;
  }

  @override
  AsyncResult<Unit> refresh() {
    return safeUnitCall(
      () async {
        final refreshToken = await SecureStorage.refreshToken.read;
        return _sessionApi.refresh(
          body: SessionRequest(
            refreshToken: refreshToken ?? '',
          ),
        );
      },
      handler: (response, action) async {
        await _sessionLocalService.saveSession(response);
      },
    );
  }

  @override
  AsyncResult<AuthStatus> checkStatus() async {
    final status = await _sessionLocalService.getAuthStatus();

    if (status != AuthStatus.authenticated) {
      await _sessionLocalService.removeSession();
    }
    return Success(status);
  }
}
