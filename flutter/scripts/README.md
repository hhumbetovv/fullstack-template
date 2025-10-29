# Scripts CLI

Automation for this workspace lives in the Dart package under `scripts/`. Run
`dart pub get` once at the repository root, then execute commands like:

```bash
fvm dart run scripts <command> [arguments]
```

or

```bash
fvms <command> [arguments]
```

Every command supports `--help` for its specific flags. Dedicated entry points
are also exposed, e.g. `fvm dart run scripts:smart_build` and `fvm dart run
scripts:module_graph`.

## Command overview

| Command | Purpose |
| ------ | ------- |
| `build` | Run the Flutter build matrix after bootstrapping the project. |
| `gen-build [modules…]` | Run `build_runner build -d` for every module that depends on build_runner or a provided subset. |
| `gen-clean [--workers <n>]` | Call `build_runner clean` for all build_runner modules (in parallel by default) and delete generated artifacts (`.g.dart`, `.freezed.dart`, etc.). |
| `gen-watch [modules…] [--pre-build]` | Launch `build_runner watch -d` for selected modules, optionally running `smart-build` first. |
| `smart-build [module] [--dry-run] [--parallel <n>] [--verbose]` | Dependency-aware incremental build orchestration. |
| `module-graph [--parallel <n>] [--verbose]` | Generate `build_graph.md` and dependency stats without executing builds. |
| `pubspec-links` | Symlink all `pubspec.yaml` files into `yaml/pubspecs/`. |
| `build-links` | Symlink all `build.yaml` files into `yaml/builds/`. |
| `yaml-links` | Runs `pubspec-links` and `build-links` back to back, cleaning previous output first. |
| `locale [--input dir] [--output file]` | Produce `LocaleKeys` constants from translation JSON files. |

## Command architecture
- `ScriptsCommand` (see `lib/src/core/base_command.dart`) wraps `Command<int>` with shared error handling, console output, and metadata wiring. New commands extend this base instead of touching boilerplate.
- `command_registry.dart` owns the list of command factories and registers them with the runner. Adding a new script only requires appending to this list—`lib/src/core/runner.dart` stays unchanged.
- Shared infrastructure lives under `lib/src/core/` (state, logging, registry, runner) and `lib/src/services/` (workspace discovery, build runner, environment, YAML). Feature-specific flows remain in `lib/src/feature/`.
- Directory layout:
  - `lib/src/core/` → base command + registry + runner + console/logging/errors.
  - `lib/src/services/` → reusable operations (toolchain, workspace, YAML, build runner).
  - `lib/src/feature/<name>/` → `feature.dart` re-exports the public API, `command/` holds CLI wiring (`command.dart`, `options.dart`), and `runner/`, `services/`, `models/` folders organise the implementation.
- Commands stay thin: parse flags in `command/command.dart` and delegate to helpers exposed via `<feature>/feature.dart`.

The CLI prefers `fvm` and falls back to the system `dart`/`flutter` binaries
when `fvm` is not installed.

## Generation helpers

### `gen-build`
- Discovers every Dart/Flutter package in the workspace.
- Filters modules that depend on `build_runner` (skipping the rest) unless a
  module list is supplied.
- Executes `fvm dart run build_runner build -d` (or plain `dart` if FVM is
  unavailable) in each target directory.
- Continues after failures but reports a non-zero exit code when any module
  fails to build.

### `gen-clean`
- Runs `build_runner clean` in all modules with a `build_runner` dependency.
- Executes clean jobs concurrently. Concurrency defaults to half the CPU count,
  but can be overridden with `--workers <n>` (or `--workers auto` for defaults).
- Removes common generated artifacts (`*.g.dart`, `*.freezed.dart`,
  `*.module.dart`, etc.) across the repository and deletes `.dart_tool/build`.

### `gen-watch`
- Starts `build_runner watch -d` in parallel for all detected build-runner
  modules or a subset matched by name/path.
- Gracefully stops watchers on `SIGINT`/`SIGTERM`.
- `--pre-build` runs `smart-build` first so dependencies are up to date before
  watchers attach.

### `smart-build`
- Builds a dependency graph for the workspace and executes `build_runner` in
  optimal order.
- Accepts an optional module name to build only that package plus its upstream
  dependencies.
- `--dry-run` prints the execution plan without running builds.
- `--parallel <n>` controls how many builds execute concurrently (default `4`).
- Generates `build_graph.md` and stores logs under `build_logs/` on successful
  runs.
- Quick entry point: `fvm dart run scripts:smart_build --dry-run`.

### `module-graph`
- Shares the same discovery and graph analysis pipeline as `smart-build` but
  skips executing `build_runner`.
- Writes the Mermaid dependency diagram to `build_graph.md` and reports unused
  dependencies.
- Quick entry point: `fvm dart run scripts:module_graph`.

## Workspace utilities

### `pubspec-links`, `build-links`, and `yaml-links`
- Traverse the repository (excluding tooling directories) and create symlinks
  under `yaml/pubspecs/` and `yaml/builds/`.
- Existing output folders are wiped before new links are created.
- Helpful for browsing all YAML config in one place without leaving an editor
  workspace.

### `locale`
- Scans JSON translation files (defaults to `app/assets/translations`).
- Generates a `sealed class LocaleKeys` with string constants for each key.
- Default output is `common/lib/src/constants/locale_keys.dart`; override
  `--output` if your keys live elsewhere (e.g. `common/shared/lib/...`).

## Build orchestration (`build` command)

The `build` command wraps the full mobile build workflow:

```bash
ANDROID_KEYSTORE_PATH=/path/to/release.jks \
ANDROID_KEYSTORE_PASSWORD=storePass \
ANDROID_KEY_ALIAS=release \
ANDROID_KEY_PASSWORD=keyPass \
fvm dart run scripts build [tokens] [flags]
```

- Always run from the repository root; the command looks for `./app` and
  `app/pubspec.yaml` to resolve metadata.
- Automatically runs `scripts/bash/bootstrap.sh` before building.
- Without positional tokens it builds every combination of platform × mode ×
  flavor (Android/iOS × debug/release × dev/prod).
- Limit the matrix by passing any combination of `android` / `ios`,
  `debug` / `release`, and `dev` / `prod` (order does not matter).
- Android release builds honour the signing environment variables. Missing or
  partially-set variables abort the run unless a pre-existing
  `android/key.properties` file is found. Debug signing is used otherwise.
- Artifacts are copied into `ignores/artifacts/<platform>/<mode>/<flavor>/`
  with the app version appended to the filename or directory name.
- iOS release builds run `flutter build ios --release --no-codesign`; debug
  builds target the simulator (`--debug --simulator`).

Key flags:
- `--android-aab` / `--android-apk` – limit Android release outputs to app
  bundles or APKs (default builds both and also produces debug APKs for debug
  runs).
- `--keep-key-properties` – keep a generated `android/key.properties` after
  release builds succeed.
- `--no-obfuscate` – skip adding `--obfuscate` to release builds (enabled by
  default).
- `--no-split-debug-info` / `--split-debug-info-path <dir>` – control
  `--split-debug-info` usage (default path `./android/app/release`).
- `--no-apply-target-platform` / `--target-platform <value>` – toggle or
  customise the `--target-platform` passed to Android builds (default
  `android-arm,android-arm64,android-x64`).

The command attempts to use `fvm flutter` and falls back to the system
`flutter` binary if FVM is unavailable.

## Adding a new command

1. Implement a command under `lib/src/feature/<name>/command/command.dart` that extends
   `ScriptsCommand` and override `Future<int> runCommand()`.
2. Put the actual workflow in `<feature>/feature.dart` and supporting `runner/` / `services/` files so that the command stays a small entrypoint.
3. Register the command by adding its factory to `command_registry.dart`.
4. Run `fvms --help` (and the command’s own `--help`) to verify the wiring.

### Example skeleton

```dart
class ExampleCommand extends ScriptsCommand {
  ExampleCommand()
      : super(
          commandName: 'example',
          commandDescription: 'Describe what the command does.',
        ) {
    argParser
      ..addFlag('dry-run', negatable: false)
      ..addOption('target');
  }

  @override
  Future<int> runCommand() async {
    // TODO: implement command
    return 0;
  }
}
```

## Migrating shell scripts

1. Identify the behaviour of the existing shell script and extract reusable
   helpers into `lib/src/<feature>/`.
2. Translate sequential shell steps to Dart using `Process.start` /
   `Process.run`, keeping repeated tasks in utilities.
3. Surface CLI flags via `argParser` so callers can configure behaviour.
4. Reuse logging utilities (or add new ones) to keep output consistent across
   commands.
5. Update documentation (including this README) and inline code comments to
   explain the new command and its usage.

After porting a script, run `dart format` on the updated files and exercise the
command locally to confirm it behaves like its shell counterpart.
