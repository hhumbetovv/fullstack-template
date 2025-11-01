import 'package:scripts/src/application/smart_build/smart_build_executor.dart';
import 'package:scripts/src/core/di/dependency_setup.dart';
import 'package:scripts/src/domain/models/smart_build_options.dart';

Future<int> runSmartBuild(SmartBuildOptions options) {
  configureDependencies();
  return getDependency<SmartBuildExecutor>().run(options);
}
