import 'package:common_shared/public.dart';
import 'package:core_data/public.dart';
import 'package:core_data/src/datasource/local/secure_storage/secure_storage.dart';
import 'package:core_data/src/datasource/local/secure_storage/secure_storage_extensions.dart';
import 'package:core_data/src/datasource/local/shared_prefs/shared_prefs.dart';
import 'package:core_data/src/datasource/local/shared_prefs/shared_prefs_extensions.dart';
import 'package:core_domain/public.dart';
import 'package:injectable/injectable.dart';

@singleton
class SessionLocalService {
  const SessionLocalService();

  Future<void> saveSession(SessionResponse data) async {
    if (!data.isValid) return;
    final refreshExpDate = data.refreshExpiration!.toString();
    final accessExpDate = data.accessExpiration!.toString();
    await Future.wait([
      SecureStorage.refreshToken.write(data.refreshToken!),
      SecureStorage.accessToken.write(data.accessToken!),
      SecureStorage.accessExpiration.write(accessExpDate),
      SecureStorage.refreshExpiration.write(refreshExpDate),
      SharedPrefs.authStatus.write(AuthStatus.authenticated),
    ]);
  }

  Future<void> removeSession() async {
    await Future.wait([
      SecureStorage.accessToken.delete(),
      SecureStorage.refreshToken.delete(),
      SecureStorage.accessExpiration.delete(),
      SecureStorage.refreshExpiration.delete(),
    ]);
  }

  Future<AuthStatus> getAuthStatus() async {
    final authStatus = AuthStatus.values.fromString(
      await SharedPrefs.authStatus.read<String>(),
    );

    if (authStatus != AuthStatus.authenticated) {
      return authStatus ?? AuthStatus.unauthenticated;
    }

    final hasRefreshToken = await SecureStorage.refreshToken.exists;

    if (!hasRefreshToken) return AuthStatus.unauthenticated;

    final tokenExpiration = await SecureStorage.refreshExpiration.read;

    if (tokenExpiration == null) return AuthStatus.unauthenticated;

    final expDate = DateTime.fromMicrosecondsSinceEpoch(
      int.parse(tokenExpiration),
    );

    final currentDate = DateTime.now();

    if (!currentDate.isBefore(expDate)) return AuthStatus.unauthenticated;

    return AuthStatus.authenticated;
  }
}
