import 'package:core_data/src/datasource/local/secure_storage/secure_storage.dart';
import 'package:core_data/src/datasource/local/secure_storage/secure_storage_service.dart';
import 'package:get_it/get_it.dart';

extension SecureStorageX on SecureStorage {
  static SecureStorageService? _cachedService;

  SecureStorageService get _service {
    _cachedService ??= GetIt.I<SecureStorageService>();
    return _cachedService!;
  }

  Future<bool> get exists async {
    return _service.isContain(name);
  }

  Future<String?> get read async {
    return _service.read(name);
  }

  Future<void> write(String newValue) async {
    await _service.write(name, newValue);
  }

  Future<void> delete() async {
    await _service.delete(name);
  }
}
