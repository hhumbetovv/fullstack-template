# Common Tooling

Utilities shared across development-time packages (scripts, generators, processor) so codegen and CLI workflows stay consistent. Import `package:tools_common/tooling.dart` when you need access to the helper surface.

## Responsibilities
- **Toolchain detection**: `ensureDartOrFvm`, `runDartCommand`, and `startDartCommand` resolve to `fvm` when available and gracefully fall back to the system `dart` binary. Scripts and builders depend on this to mirror the user’s Flutter setup.
- **Path helpers**: `normalizePosix`, `normalizeSystemPath`, `ensureDotRelative`, and `DirectoryWalker` keep repository traversal predictable and avoid duplicated ignore lists.
- **Cache coordination**: `buildCacheDirectory`, `buildCacheFilePath`, and `effectsCachePath` standardise on `.dart_tool/build/cache` so cleaners and generators never drift apart.
- **Effect metadata**: `EffectCache`, `CachedEffect`, and supporting DTOs persist the view/view-model relationship for `gen_view_kit`, allowing incremental builds without importing heavy runtime packages.

## Typical consumers
- **Scripts CLI** uses the toolchain API to launch `build_runner`, resolves workspace modules with `DirectoryWalker`, and wipes caches with the shared constants.
- **Generator packages** consult `buildCacheFilePath` for cached config snapshots and the effect cache helpers to share data between view and view-model builders.
- **Processor & other dev-only packages** can opt into the same helpers to avoid re-implementing path traversal or platform detection.

## Getting started
1. Add `tools_common` as a workspace dependency (see the root `pubspec.yaml`).
2. Import the barrel file: 
   ```dart
   import 'package:tools_common/tooling.dart';
   ```
3. Wrap external tool invocations via `runDartCommand`/`startDartCommand` instead of calling `Process.run('dart', ...)` directly.
4. Use `DirectoryWalker` to scan modules or config files while honouring the shared skip list (`.git`, `.dart_tool`, `node_modules`, etc.).
5. When writing to `.dart_tool/build/cache`, rely on `buildCacheFilePath` or `effectsCachePath` to keep layout consistent with other tooling.

## Notable APIs
- `ensureDartOrFvm(requirePubspec: true)` throws early if no Dart toolchain is available or the working directory is not a package (mirrors Scripts CLI behaviour).
- `DirectoryWalker.findFilesNamed('pubspec.yaml')` breadth-first scans without following symlinks and skips ignored folders.
- `EffectCache.readForViewModel('MyViewModel')` returns cached effect metadata as plain Dart objects; `upsertViewEffects` replaces a view’s entries atomically.

## Contributing tips
- Keep dependencies minimal (pure Dart where possible) so scripts and generators can import this package without pulling in Flutter.
- Document any new helper in this README, and consider adding short code samples for complex workflows.
- Don’t store runtime-only utilities here; this package exists strictly for development tooling.
- If you add new cache files, define constants/functions here so clean-up commands stay in sync.
