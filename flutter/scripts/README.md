# Template Scripts CLI

Project automation commands are now provided via a Dart CLI package. You can run
the commands from the repository root once packages are fetched:

```bash
dart run scripts <command> [options]
```

## Available commands

- `smart-build` – incremental `build_runner` orchestration with dependency graph awareness.
  - Kısayol: `dart run scripts:smart_build --dry-run`
- `module-graph` – bağımlılık grafiğini ve istatistikleri `build_graph.md` dosyasına üretir.
  - Kısayol: `dart run scripts:module_graph`

## Adding a new command

1. Create a file under `lib/src/commands` that extends `Command<int>`.
2. Place reusable logic in `lib/src/<feature>` so it can be imported by other commands.
3. Register the command in `lib/src/runner.dart`.
4. Run `dart run scripts --help` to verify the command is discoverable.

### Example skeleton

```dart
class ExampleCommand extends Command<int> {
  ExampleCommand() {
    argParser
      ..addFlag('dry-run', negatable: false)
      ..addOption('target');
  }

  @override
  String get name => 'example';

  @override
  String get description => 'Describe what the command does.';

  @override
  Future<int> run() async {
    // TODO: implement command
    return 0;
  }
}
```

## Migrating shell scripts

1. Identify script behaviour and extract any reusable helpers into `lib/src/<feature>`.
2. Translate sequential shell steps to Dart using the `Process.start` / `Process.run`
   APIs, and wrap repeated tasks in helper functions or classes.
3. Surface CLI flags via `argParser` so behaviour can be configured from the command line.
4. Reuse logging utilities (or add new ones) to keep the output consistent across commands.
5. Update documentation (`README.md`, inline comments) to explain the new command and its usage.

When everything compiles, run `dart format` on the updated files and execute the command locally
to ensure the behaviour matches the previous shell script.
