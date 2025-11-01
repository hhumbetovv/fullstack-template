import 'dart:convert';
import 'dart:io';

import 'package:common_tooling/tooling.dart';
import 'package:scripts/src/core/logging/logging.dart';
import 'package:scripts/src/core/state/build_state.dart';

part 'build_execution/log_manager.dart';
part 'build_execution/module_builder.dart';
part 'build_execution/build_scheduler.dart';

class BuildExecutionService {
  BuildExecutionService(this.state);

  final BuildState state;

  Future<bool> execute() => executeSmartBuildInternal(state);
}
