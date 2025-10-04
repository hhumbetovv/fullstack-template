import 'package:core_domain/public.dart';

abstract class SessionRepository {
  AsyncResult<Unit> refresh();
  AsyncResult<Unit> logout();
  AsyncResult<AuthStatus> checkStatus();
}
