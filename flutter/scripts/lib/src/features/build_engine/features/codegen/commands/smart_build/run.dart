import 'package:scripts/src/core/di/dependency_setup.dart';
import 'package:scripts/src/features/build_engine/features/codegen/commands/smart_build/smart_build_executor.dart';
import 'package:scripts/src/features/build_engine/features/codegen/domain/models/smart_build_options.dart';

Future<int> runSmartBuild(SmartBuildOptions options) {
  configureDependencies();
  return getDependency<SmartBuildExecutor>().run(options);
}
