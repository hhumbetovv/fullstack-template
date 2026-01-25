import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/logging/console.dart';

/// Base class for scripts commands that provides consistent error handling
/// and metadata wiring. Extend this instead of [Command] directly so new
/// commands behave like existing ones.
abstract class ScriptsCommand extends Command<int> {
  ScriptsCommand({
    required this.commandName,
    required this.commandDescription,
    List<String> aliases = const [],
  }) : commandAliases = List.unmodifiable(aliases);

  final String commandName;
  final String commandDescription;
  final List<String> commandAliases;

  @override
  String get name => commandName;

  @override
  String get description => commandDescription;

  @override
  List<String> get aliases => commandAliases;

  /// Entry point subclasses must implement. Always return an exit code.
  FutureOr<int> runCommand();

  /// Override to show the stack trace when unexpected errors occur.
  bool get showStackTrace => false;

  @override
  Future<int> run() async {
    try {
      final result = await runCommand();
      return result;
    } on CommandError catch (error) {
      Console.error(error.message);
      return error.exitCode;
    } on SmartBuildException catch (error) {
      if (error.message.isNotEmpty) {
        Console.error(error.message);
      }
      return error.exitCode;
    } on UsageException catch (error) {
      Console.error(error.message);
      Console.write(error.usage);
      return 64;
    } on Object catch (error, stackTrace) {
      Console.error('Unexpected error: $error');
      if (showStackTrace) {
        Console.write(stackTrace.toString());
      }
      return 1;
    }
  }
}
