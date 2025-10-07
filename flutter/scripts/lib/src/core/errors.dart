class CommandError implements Exception {
  const CommandError(this.message, {this.exitCode = 1});

  final String message;
  final int exitCode;

  @override
  String toString() => message;
}
