//@GeneratedMicroModule;DemoDomainPackageModule;package:demo_domain/init.module.dart
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i687;

import 'package:demo_domain/src/repository/demo_repository.dart' as _i541;
import 'package:demo_domain/src/usecase/demo_usecase.dart' as _i872;
import 'package:injectable/injectable.dart' as _i526;

class DemoDomainPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.factory<_i872.DemoUseCase>(
        () => _i872.DemoUseCase(repository: gh<_i541.DemoRepository>()));
  }
}
