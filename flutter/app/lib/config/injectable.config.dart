// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:core_data/init.module.dart' as _i190;
import 'package:demo_presentation/init.module.dart' as _i407;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import './router.dart' as _i285;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> $initLocator({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    await _i190.CoreDataPackageModule().init(gh);
    await _i407.DemoPresentationPackageModule().init(gh);
    gh.singleton<_i285.AppRouter>(() => _i285.AppRouter());
    return this;
  }
}
