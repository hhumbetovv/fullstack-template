# Scripts CLI

Automation lives in the `scripts/` Dart package. Install dependencies once:

```bash
cd scripts
fvm dart pub get
```

Run commands via FVM (recommended). After running the bootstrap script a shell alias `fvms`
is available and maps to `fvm dart run scripts`:

```bash
fvms <command> [flags]
```

If the alias is unavailable, fall back to:

```bash
fvm dart run scripts <command> [flags]
```

Each command exposes `--help`. Shortcut entrypoints (`scripts:<command>`) are available for frequently used flows.

---

## Directory layout

```
scripts/lib/src/
├── cli/                # Thin CommandRunner wrappers (build, gen-*, smart_build …)
├── application/        # Orchestrators & workflows per vertical (build, gen, module_graph, links, locale, smart_build)
├── domain/             # DTOs and port interfaces shared across features
├── infrastructure/     # Port implementations (build_runner, workspace discovery, graph generation, build tooling, links)
└── core/               # Cross-cutting pieces (commands base class, DI setup, logging, state)
```

- **CLI** (`cli/`): parse flags/options, call `configureDependencies()`, then resolve an executor with `getDependency<T>()` and delegate work.
- **Application**: orchestrators (e.g. `build_executor.dart`, `gen_executor.dart`, `module_graph_executor.dart`) combine workflows/helpers into higher-level operations.
- **Domain**: simple models (`BuildSpec`, `SmartBuildOptions`, `ModuleGraphOptions`, `ModuleDescriptor`, `BuildPlan`, `DependencyReport`, `GraphReport`) and port abstractions (`BuildRunnerPort`, `ModuleDiscoveryPort`, `ModuleGraphPort`).
- **Infrastructure**: adapters for file system/process/network concerns (Android/iOS builders, link creator, workspace scanner, build_runner service, module graph generation helpers).
- **Core**: `CommandError` handling, console logging, BuildState store, and GetIt DI under `core/di`.

## Dependency injection

`core/di/dependency_setup.dart` registers all executors, ports, and services with GetIt. Each CLI command calls `configureDependencies()` before resolving its orchestrator via `getDependency<T>()`. Use GetIt scopes in tests to override registrations.

## Command summary

| Command                                                          | Description                                                                                                                                                                                     |
| ---------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `create-module <feature-path> <module-type>`                     | Scaffold a module under `feature/` from `scripts/templates/modules/<module-type>`, append the module path to the workspace list, and regenerate the module graph.                               |
| `modules-sync [--modules <name\|path>…] [module…]`               | Sync every module’s `pubspec.yaml` from its `module.yaml` plus root `workspace_modules.yaml` definitions.                                                                                    |
| `build`                                                          | Execute the mobile build matrix (Android/iOS × mode × flavour). Use `--flavor`, `--debug`, or `--release` to filter. Artifacts land in `.misc/artifacts/`.                                      |
| `gen-build [modules…]`                                           | Run `build_runner build -d` for all build_runner packages or a filtered set. `foo_feature` expands to `foo_data`, `foo_domain`, `foo_presentation`, `foo_data_api`, and `foo_presentation_api`. |
| `gen-clean [--workers <n>]`                                      | Clean generated files and run `build_runner clean` across modules.                                                                                                                              |
| `gen-watch [modules…] [--pre-build]`                             | Launch `build_runner watch -d`, optionally running `smart-build` first. Accepts the same `<feature>_feature` shortcuts as `gen-build`.                                                          |
| `smart-build [module?] [--dry-run] [--parallel <n>] [--verbose]` | Dependency-aware incremental build orchestration with mermaid output.                                                                                                                           |
| `module-graph [--parallel <n>] [--verbose]`                      | Generate dependency graphs/stats without executing builds.                                                                                                                                      |
| `build-links`                                                    | Symlink all `build.yaml` files into `yaml/builds/`.                                                                                                                                             |
| `pubspec-links`                                                  | Symlink all `pubspec.yaml` files into `yaml/pubspecs/`.                                                                                                                                         |
| `yaml-links`                                                     | Run both linkers sequentially (clears previous output).                                                                                                                                         |
| `locale [--input dir] [--output file]`                           | Produce locale key constants from translation JSON.                                                                                                                                             |

_All commands support `--help` for detailed flags._

### Module specs

`modules-sync` keeps all `pubspec.yaml` files aligned with two lightweight configuration layers:

1. `workspace_modules.yaml` (repo root) stores the canonical Dart SDK constraint plus a `packages:` map of package → version.
2. Each workspace module owns a `module.yaml` with its `name`, `modules`/`dev_modules` (internal workspace dependencies), and `dependencies`/`dev_dependencies` (third-party package names without versions).

Running `fvms modules-sync` applies the central versions to every module. Pass module names or paths to limit the update set: `fvms modules-sync --modules core_data feature/demo/presentation`. Add `--reverse` to derive minimal `module.yaml` specs from the current `pubspec.yaml` contents (useful after manual pubspec edits).

Additional flags help during maintenance:

- `--check`: dry-run and fail if any pubspec would change.
- `--packages dio retrofit`: only touch modules that depend on the listed packages.
- `--format`: sort & rewrite every `module.yaml` (dedupe lists, lint field order) before syncing.
- `--reverse`: write `module.yaml` files based on the current pubspec dependencies (incompatible with `--format`, `--lock`, and `--report`).
- `--lock`: emit `build_info/modules_lock.yaml` summarising every module’s resolved third-party package versions.
- `--report`: emit `build_info/dependencies.md` containing a Markdown dependency digest per module.

Flags can be combined: e.g. `fvms modules-sync --packages dio --lock --report` updates just dio consumers, writes new pubspecs, a lock snapshot, and the dependency report in one pass.

### Module graph outputs

Running `module-graph` now produces four focused Mermaid files under `build_info/`:

1. `foundation.md` – shows all non-feature modules and how they feed into feature modules.
2. `features.md` – isolates only the feature packages and their inter-dependencies.
3. `waves.md` – groups every module by build wave (subgraphs per wave).
4. `layers.md` – clusters modules by layer (core/common/ui/data/domain) and by each feature area.

## Key workflows

### Build

- Automatically discovers available flavours from `.env.*` files under `app/` and expands the build matrix across all platforms/modes unless filters are provided.
- Uses `BuildExecutor` → Android & iOS builders (`infrastructure/build/*`).
- Android release builds expect signing env vars (`ANDROID_KEYSTORE_PATH`, etc.) or an existing `android/key.properties`.
- Flags: `--flavor <name>`, `--debug`, `--release`, `--android-aab`, `--android-apk`, `--keep-key-properties`, `--no-obfuscate`, `--no-split-debug-info`, `--split-debug-info-path`, `--no-apply-target-platform`, `--target-platform`.

### Gen

- `GenExecutor` discovers modules via `ModuleDiscoveryPort` and drives specific workflows: `build_runner` builds, clean queue (multi-worker), or watch processes.
- `--workers` defaults to half CPU count; `--pre-build` on `gen-watch` triggers smart-build before watchers attach.
- Filters support `<feature>_feature` shortcuts (e.g. `auth_feature`) which expand to every module in that feature’s `data`, `domain`, `presentation`, `data_api`, and `presentation_api` packages. The shortcut works for both `gen-build` and `gen-watch`.

### Smart-build & Module-graph

- Shared module discovery and dependency analysis via `ModuleGraphPort` (`ModuleGraphService`).
- Smart-build executes builds in dependency order; `--dry-run` prints the plan without running.
- Module-graph generates `build_info/*.md` mermaid diagrams plus summary stats.

### Links & Locale

- `LinksExecutor` creates symlinks in `yaml/` for quick inspection.
- `LocaleExecutor` scans JSON translations and writes a `LocaleKeys` class.

## Adding a command

1. Create a command in `lib/src/cli/<name>/command.dart` extending `ScriptsCommand`.
2. Optionally add an options helper in the same folder.
3. Wire the actual work in `application/<domain>/...` (or reuse existing executors).
4. Register the command factory in `core/command/command_registry.dart`.
5. `dart analyze` + `fvms <command> --help` (or `fvm dart run scripts <command> --help`) to confirm wiring.

### Command skeleton

```dart
class ExampleCommand extends ScriptsCommand {
  ExampleCommand() : super(commandName: 'example', commandDescription: '...');

  @override
  Future<int> runCommand() {
    configureDependencies();
    final executor = getDependency<ExampleExecutor>();
    return executor.run();
  }
}
```

## Misc

- Bootstrap script: `sh scripts/bash/bootstrap.sh`
- Logs: `build_logs/`, graphs under `build_info/`
- Build artifacts are also staged under `.misc/artifacts/` for grab-and-go archives

Happy automating!

### Module templates

Module scaffolding pulls files from `scripts/templates/modules/<module-type>/`.
Each file is copied into the target module directory and placeholders such as
`{{module_name}}`, `{{feature_name}}`, and `{{module_type}}` are replaced. Add
any additional files (e.g. `lib/` skeletons) to those template folders and they
will be included automatically during `fvms create-module`.

Place a file named `.template_dir` inside any template directory you want to
keep even when it is otherwise empty (e.g. `lib/.template_dir`). The scaffolder
creates the folder but ignores the marker file, keeping generated modules clean.
Each successful run also appends the new module path (relative to repo root) to
the root `pubspec.yaml` `workspace` list and triggers `module-graph` so the
documentation stays up to date.
