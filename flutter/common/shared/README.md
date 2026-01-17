# Common Shared

Reusable foundation pieces that other packages rely on for constants, environment setup, logging, and lightweight utilities. Import `package:common_shared/public.dart` when you need the whole toolset.

## Responsibilities
- **Configuration hooks**: `CommonSharedConfig().setup()` lets the host app register a custom console formatter, enabling colorized logs or Crashlytics integration in one place.
- **Environment management**: `Environment.initialize()` loads `.env.<flavor>` files and exposes `Flavor.current` and typed accessors such as `Environment.baseUrl`.
- **Constants**: String keys, regexes, message types, web URLs, and other values that need to stay consistent across modules.
- **Extensions**: Helpers on `String`, `DateTime`, `Iterable`, enums, and nullable types to trim repetitive code when validating inputs or formatting data.
- **Utilities**: `Console` for structured logging, ANSI color helpers, debounce control, simple console history export, etc.

## Typical consumers
- **Core data / network packages** reuse constants (API endpoints, regexes) and environment helpers to bootstrap clients.
- **Domain and presentation layers** depend on `MessageType`, `AppStrings`, and collection extensions when building UI or validation flows.
- **Feature modules** access logging (`Console`), debounce utilities, and flavour-specific config without re-implementing infrastructure.

## Getting started
1. Add `common_shared` as a dependency in your package.
2. Import the public barrel: `import 'package:common_shared/public.dart';`.
3. Ensure `.env.<flavor>` files exist under both the repository root and `app/` so tooling and platform builds share the same configuration.
4. During app bootstrap, configure: 
   ```dart
   Future<void> main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Environment.initialize();
     CommonSharedConfig().setup(
       consoleFormatter: (format, date) => DateFormat(format).format(date ?? DateTime.now()),
     );
   }
   ```
5. Use the exported constants, extensions, and utilities throughout your module.

## Notable APIs
- `Console.log(message, color, tag)` records colorized logs and keeps a bounded history (`Console.history`). (See common/presentation/README.md for how presentation modules consume the logging hooks.)
- `Console.exportLogsAsStrings()` produces a serializable dump that can be attached to bug reports.
- `Debounce(milliseconds: 300).call(action)` throttles rapid UI events such as search field updates.
- `StringX.ifEmpty(fallback)` and `NullableStringX.isNullOrEmpty()` simplify user input handling.
- `Flavor.current` evaluates once based on the compile-time `--dart-define=FLAVOR`.

## Contributing tips
- Prefer adding new constants or helpers here instead of duplicating logic in feature modules.
- Keep added dependencies lightweight; this package should remain platform-agnostic and safe to import from pure Dart code.
- Document new utilities in this README so other teams discover them quickly.
