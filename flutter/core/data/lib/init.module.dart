//@GeneratedMicroModule;CoreDataPackageModule;package:core_data/init.module.dart
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i687;

import 'package:core_data/src/datasource/local/secure_storage/secure_storage_service.dart'
    as _i908;
import 'package:core_data/src/datasource/local/session_local_service.dart'
    as _i642;
import 'package:core_data/src/datasource/local/shared_prefs/shared_prefs_service.dart'
    as _i119;
import 'package:core_data/src/datasource/remote/session_api.dart' as _i872;
import 'package:core_data/src/module/network_module.dart' as _i920;
import 'package:core_data/src/repository/session_repository_impl.dart' as _i170;
import 'package:core_domain/public.dart' as _i904;
import 'package:dio/dio.dart' as _i361;
import 'package:injectable/injectable.dart' as _i526;

class CoreDataPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    final networkModule = _$NetworkModule();
    gh.singletonAsync<_i119.SharedPrefsService>(() {
      final i = _i119.SharedPrefsService();
      return i.init().then((_) => i);
    });
    gh.singleton<_i642.SessionLocalService>(
        () => const _i642.SessionLocalService());
    gh.singleton<_i908.SecureStorageService>(
        () => _i908.SecureStorageService());
    gh.singleton<_i361.Dio>(() => networkModule.dio);
    gh.factory<_i872.SessionApi>(() => _i872.SessionApi.new(gh<_i361.Dio>()));
    gh.lazySingleton<_i904.SessionRepository>(() => _i170.SessionRepositoryImpl(
          gh<_i642.SessionLocalService>(),
          gh<_i872.SessionApi>(),
        ));
  }
}

class _$NetworkModule extends _i920.NetworkModule {}
