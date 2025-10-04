import 'package:core_data/src/datasource/local/shared_prefs/shared_prefs.dart';
import 'package:core_data/src/datasource/local/shared_prefs/shared_prefs_service.dart';
import 'package:get_it/get_it.dart';

extension SharedPrefsX on SharedPrefs {
  static SharedPrefsService? _cachedService;

  Future<SharedPrefsService> get _service async {
    _cachedService ??= await GetIt.I.getAsync<SharedPrefsService>();
    return _cachedService!;
  }

  Future<bool> exists() async {
    return (await _service).isContain(name);
  }

  Future<T?> read<T>() async {
    return (await _service).read<T>(name);
  }

  Future<bool> write<T>(T val) async {
    return (await _service).write(name, val);
  }

  Future<bool> delete() async {
    return (await _service).delete(name);
  }
}
