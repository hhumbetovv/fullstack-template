import 'package:core_data/init.module.dart';
import 'package:demo_presentation/init.module.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injectable.config.dart';

final locator = GetIt.I;

@InjectableInit(
  initializerName: r'$initLocator',
  preferRelativeImports: true,
  asExtension: true,
  externalPackageModulesBefore: [
    ExternalModule(CoreDataPackageModule),
    ExternalModule(DemoPresentationPackageModule),
  ],
)
Future<void> configureDependencies() async {
  await locator.$initLocator();
}
