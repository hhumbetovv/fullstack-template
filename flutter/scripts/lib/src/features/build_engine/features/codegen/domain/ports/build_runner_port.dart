import 'dart:async';
import 'dart:io';

abstract class BuildRunnerPort {
  Future<ProcessResult> runCommand(
    Directory directory,
    List<String> args, {
    bool forwardOutput = true,
  });

  Future<Process> startWatch(
    Directory directory,
    List<String> extraArgs,
  );

  Future<void> cancelProcesses(List<Process> processes);

  void deleteGeneratedArtifacts();
}
