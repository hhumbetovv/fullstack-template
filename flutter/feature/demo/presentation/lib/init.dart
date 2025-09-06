import 'package:demo_data/init.module.dart';
import 'package:demo_domain/init.module.dart';
import 'package:injectable/injectable.dart';

@InjectableInit.microPackage(
  externalPackageModulesBefore: [
    ExternalModule(DemoDomainPackageModule),
    ExternalModule(DemoDataPackageModule),
  ],
)
void initMicroPackage() {}
