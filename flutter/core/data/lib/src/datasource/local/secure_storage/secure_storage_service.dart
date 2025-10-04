import 'package:common_shared/public.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@singleton
class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> write(String key, String val) async {
    Console.log(
      '🔒 SECURE PREFS | WRITE\n'
          'KEY: $key\n'
          'VALUE: $val\n',
      AnsiColors.cyan,
      'Prefs',
    );
    await _storage.write(key: key, value: val);
  }

  Future<String?> read(String key) async {
    final result = await _storage.read(key: key);
    Console.log(
      '🔒 SECURE PREFS | READ\n'
          'KEY: $key\n'
          'VALUE: $result\n',
      AnsiColors.cyan,
      'Prefs',
    );
    return result;
  }

  Future<void> delete(String key) async {
    Console.log(
      '🔒 SECURE PREFS | DELETE\n'
          'KEY: $key\n',
      AnsiColors.cyan,
      'Prefs',
    );
    await _storage.delete(key: key);
  }

  Future<bool> isContain(String key) async {
    final isExists = await _storage.containsKey(key: key);
    Console.log(
      '🔒 SECURE PREFS | CONTAINS\n'
          'KEY: $key\n'
          'RESULT: $isExists ${isExists ? '✅' : '🛑'}\n',
      AnsiColors.cyan,
      'Prefs',
    );
    return isExists;
  }
}
