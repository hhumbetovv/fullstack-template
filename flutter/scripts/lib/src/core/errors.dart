class CommandError implements Exception {
  const CommandError(this.message, {this.exitCode = 1});

  final String message;
  final int exitCode;

  @override
  String toString() => message;
}

class SmartBuildException implements Exception {
  const SmartBuildException(this.message, {this.exitCode = 1});

  final String message;
  final int exitCode;

  @override
  String toString() => message;
}
