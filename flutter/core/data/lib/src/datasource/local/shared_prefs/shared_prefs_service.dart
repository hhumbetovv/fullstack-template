import 'package:common_shared/public.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef StringList = List<String>;

@singleton
final class SharedPrefsService {
  SharedPrefsService();

  static SharedPreferences? _storage;

  @PostConstruct()
  Future<void> init() async {
    _storage = await SharedPreferences.getInstance();
  }

  Future<bool> write<T>(String key, T val) {
    if (_storage == null) {
      throw UnimplementedError('Shared Preferences has not been initialized');
    }
    Console.log(
      '💾 PREFS | WRITE\n'
          'KEY: $key\n'
          'VALUE: $val\n',
      AnsiColors.cyan,
      'Prefs',
    );
    if (val is Enum) {
      return _storage!.setString(key, val.name);
    }
    return switch (T) {
      const (String) => _storage!.setString(key, val as String),
      const (int) => _storage!.setInt(key, val as int),
      const (double) => _storage!.setDouble(key, val as double),
      const (bool) => _storage!.setBool(key, val as bool),
      const (StringList) => _storage!.setStringList(key, val as StringList),
      _ => throw Exception('Unknown type'),
    };
  }

  T? read<T>(String key) {
    if (_storage == null) {
      throw UnimplementedError('Shared Preferences has not been initialized');
    }
    final result = switch (T) {
      const (String) => _storage!.getString(key),
      const (int) => _storage!.getInt(key),
      const (double) => _storage!.getDouble(key),
      const (bool) => _storage!.getBool(key),
      const (StringList) => _storage!.getStringList(key),
      _ => throw Exception('Unknown type'),
    };
    Console.log(
      '💾 PREFS | READ\n'
          'KEY: $key\n'
          'VALUE: $result\n',
      AnsiColors.cyan,
      'Prefs',
    );
    return result as T?;
  }

  Future<bool> delete(String key) {
    if (_storage == null) {
      throw UnimplementedError('Shared Preferences has not been initialized');
    }
    Console.log(
      '💾 PREFS | DELETE\t'
          'Key: $key\n',
      AnsiColors.cyan,
      'Prefs',
    );
    return _storage!.remove(key);
  }

  bool isContain(String key) {
    if (_storage == null) {
      throw UnimplementedError('Shared Preferences has not been initialized');
    }
    final isExists = _storage!.containsKey(key);
    Console.log(
      '💾 PREFS | CONTAINS\n'
          'Key: $key\t'
          'RESULT: $isExists ${isExists ? '✅' : '🛑'}\n',
      AnsiColors.cyan,
      'Prefs',
    );
    return isExists;
  }
}
