import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injectable.config.dart';

@InjectableInit(
  initializerName: r'$initLocator',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies() {
  GetIt.I.$initLocator();
}
