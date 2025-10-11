# Template Scripts CLI

Project automation commands are now provided via a Dart CLI package. You can run
the commands from the repository root once packages are fetched:

```bash
dart run scripts <command> [options]
```

## Available commands

- `gen-build [modules…]` – runs `build_runner build` for the listed modules or every module.
- `gen-clean` – runs `build_runner clean` for every module and removes generated artifacts.
- `gen-watch [modules…] [--pre-build]` – starts `build_runner watch` for the selected modules.
- `smart-build` – incremental `build_runner` orchestration with dependency tracking.
  - Shortcut: `dart run scripts:smart_build --dry-run`
- `module-graph` – writes the dependency graph and stats to `build_graph.md`.
  - Shortcut: `dart run scripts:module_graph`
- `pubspec-links` – symlinks every `pubspec.yaml` into `yaml/pubspecs/`.
- `build-links` – symlinks every `build.yaml` into `yaml/builds/`.
- `yaml-links` – runs both `pubspec-links` and `build-links` back to back.
- `locale --input <dir> --output <file>` – generates `LocaleKeys` from JSON translation files.

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

1. Identify script behavior and extract any reusable helpers into `lib/src/<feature>`.
2. Translate sequential shell steps to Dart using the `Process.start` / `Process.run`
   APIs, and wrap repeated tasks in helper functions or classes.
3. Surface CLI flags via `argParser` so behavior can be configured from the command line.
4. Reuse logging utilities (or add new ones) to keep the output consistent across commands.
5. Update documentation (`README.md`, inline comments) to explain the new command and its usage.

When everything compiles, run `dart format` on the updated files and execute the command locally
to ensure the behavior matches the previous shell script.

## Build orchestration

Use the Dart CLI command to run the bootstrap flow and produce platform builds:

```bash
ANDROID_KEYSTORE_PATH=/path/to/release.jks \
ANDROID_KEYSTORE_PASSWORD=storePass \
ANDROID_KEY_ALIAS=release \
ANDROID_KEY_PASSWORD=keyPass \
dart run scripts build
```

- Running without extra arguments produces every combination for Android & iOS (`debug`/`release` × `dev`/`prod`).
- Add any mix of `android`/`ios`, `debug`/`release`, and `dev`/`prod` tokens to restrict the output.
  - Example: `dart run scripts build android release dev` produces only the Android release dev artifact.
- `--keep-key-properties` keeps the generated `android/key.properties` file in place.
- Every artifact is copied under `ignores/artifacts/` with the app version appended to the file or directory name.
- `--android-aab` / `--android-apk` limit Android release output to the selected artifact types (default builds both).
- `--no-obfuscate`, `--no-split-debug-info`, and `--split-debug-info-path <dir>` control release obfuscation and debug-info emission (defaults enable both with `./android/app/release`).
- `--no-apply-target-platform` skips adding `--target-platform`; use `--target-platform <value>` to override the default `android-arm,android-arm64,android-x64`.

When the Android signing environment variables are present the command uses them; otherwise Gradle falls back to the debug signing config. The command invokes
`scripts/bootstrap.sh`, creates a temporary `android/key.properties` file when needed, and calls Flutter with both `--flavor <name>` and
`--dart-define=FLAVOR=<name>` for each build.
