# Common Presentation

Shared presentation helpers that sit between raw Flutter widgets and feature-specific UI. Import `package:common_presentation/public.dart` to access keys, extensions, and utilities.

## Responsibilities
- **Global configuration**: `CommonPresentationConfig.setup(snackBarBuilder: ...)` lets the host app supply a branded `SnackBar` factory used by presentation modules (see core/presentation/README.md for how generated views consume it).
- **Global keys**: `messengerKey` and `applicationKey` are reused across routing layers, debug tooling, and overlay managers.
- **Context extensions**: Methods such as `context.safeBottomValue`, `context.width`, and `context.height` reduce direct `MediaQuery` boilerplate.
- **TextStyle helpers**: `textStyle.withScaler(scaler)` or `.colored(color)` simplify typography adjustments when working with custom text scaling strategies.
- **Debug utilities**: `UiDebugger.toggleDebugPaint()` cycles through Flutter’s debug paint flags and rebuilds the widget tree to reflect changes, making it easy to inspect layout issues in dev builds.
- **Log formatting**: `String.format()` prettifies nested data structures in debug mode so complex objects are readable in the console.

## Typical consumers
- **Core presentation** and generated view-model widgets rely on the global keys and extensions when wiring scaffolds, snackbars, or safe insets.
- **Feature presentation** packages use the context & text style extensions to keep layout code terse and consistent.
- **Design-system tooling** leverages `UiDebugger` and logging helpers while iterating on new UI components.

## Getting started
1. Add `common_presentation` as a dependency.
2. Import the barrel file: `import 'package:common_presentation/public.dart';`.
3. Bootstrap configuration early (e.g. in `main()`):
   ```dart
   CommonPresentationConfig.setup(
     snackBarBuilder: (message, type) => SnackBar(content: Text(message)),
   );
   ```
4. Wire global keys into your `MaterialApp` / router setup: 
   ```dart
   return MaterialApp(
     scaffoldMessengerKey: messengerKey,
     navigatorKey: applicationKey,
     // ...
   );
   ```
5. Replace manual `MediaQuery` or style adjustments with the provided extensions: 
   ```dart
   Padding(
     padding: context.safeBottomPadding,
     child: Text('Hello', style: Theme.of(context).textTheme.bodyMedium.colored(Colors.white)),
   );
   ```

## Notable APIs
- `ContextExtensions.safeBottomPadding` / `.safeTopValue` for safe-area aware layouts.
- `UiText` formatting via `String.format()` for prettier debug logs when printing generated entities.
- `UiDebugger.toggleDebugPaint()` to inspect hit regions, repaint bounds, and baselines without leaving the app.

## Contributing tips
- Add new presentation-wide helpers here so they are available to both feature modules and generator output.
- Keep APIs framework-agnostic where possible (pure extensions over Flutter types) so downstream generated code can depend on them without heavy coupling.
- Update this README whenever you introduce new configuration knobs or utilities to help newcomers onboard quickly.
