# Generator Builders

This directory hosts the code generators that expand the annotations defined in `processor`. Each subpackage contains a builder class, resolver, and factory responsible for transforming analyzer metadata into generated Dart source.

## Overview of builders

| Package | Annotation(s) | Output | Typical consumers |
| ------- | -------------- | ------ | ----------------- |
| `data` | `@data` | Immutable value types with copy/apply extensions, equality, and optional `LoadableState` glue | Feature/domain state classes, use-case params |
| `palette` | `@palette`, `@rootPalette` | Palette value objects, lerp extensions, `ThemeExtension` implementations | UI kit palettes and theme definitions |
| `view_kit` | `@view`, `@provider`, `@viewModel`, `@intent`, `@effect` | Widget scaffolding, provider wrappers, sealed intent/effect classes, base view-model subclasses | Presentation layer across features |
| `exporter` | (no annotations) | Aggregated `public.dart` exporting selected folders | Packages that want a single re-export surface |

Each builder is wired in its package’s `build.yaml` and usually produces `.g.dart` part files next to the source library (see processor/README.md for the annotations they respond to). Some builders (e.g. exporter) emit additional outputs.

## Common workflow

1. A developer annotates source code in a feature/package using `processor` markers.
2. Running `dart run build_runner build` invokes the relevant builders.
3. The builder’s resolver emits a config DTO (`DataConfig`, `ViewConfig`, etc.) and the factory renders final Dart code.
4. Generated files are imported via the `part '...g.dart';` directive in the annotated library.

Because the builders depend on `generator/core`, they inherit caching behaviour, formatting, and error handling (see generator/core/README.md for the shared infrastructure).

## Builder specifics

### Data builder (`generator/builder/data`)
- Ensures factory constructors either mark fields as required or provide defaults.
- Generates `_ClassName` implementations, getters, `copy` methods (with `() => value` semantics for nullable fields), and `apply<Field>` helpers.
- Automatically implements `LoadableState` when a field named `isLoading` is present, enabling `BaseViewModel.runWithLoading` support downstream.

### Palette builder (`generator/builder/palette`)
- Extends the data builder to emit lerp logic for colors, gradients, and nested palette objects.
- The `root_palette` variant (`RootPaletteBuilder`) also generates `ThemeExtension` boilerplate (`copyWith`, `lerp`, `type`) so palettes integrate with Flutter theming.

### View kit builder (`generator/builder/view_kit`)
- Generates three families of code:
  - `_View` classes wrapping `ViewModelProvider`, wiring effect listeners, and exposing a `buildView` override.
  - Provider widgets with `child` slots for composing shared scopes.
  - View-model bases, sealed intents/effects, state typedefs, and helper extensions (`Intent.dispatch`, selectors).
- **Effect caching:** When a view is processed, its `EffectConfig` list is stored in `.dart_tool/build/cache/effects_cache.json`. View-model generation reads this cache to learn which view methods consume its effects. If you add or rename an effect handler in a view, re-run the builder so the view-model is regenerated; otherwise the cache will be stale and effect dispatch may throw at runtime.
- Checks for naming collisions between intents and effects, and warns when overrides (e.g. `viewModelFactory`) are present so generated code can honour custom logic.

### Exporter builder (`generator/builder/exporter`)
- Scans configured folders (relative to `lib/src/`) and emits a sorted list of `export` statements into `lib/public.dart`.
- **Configuration:** Add the target folders to the package `build.yaml`:
  ```yaml
  targets:
    $default:
      builders:
        gen_exporter|exporter
          options:
            folders:
              - components
              - palette
  ```
  If a folder is omitted, its libraries will not be exported.
- Ignores `part` files and libraries declaring `part of` to avoid duplicate exports.

## Working with the builders

- Always keep `processor` annotations, config DTOs, and builder logic in sync. A mismatch leads to runtime errors or missing generated code.
- When debugging effect behaviour, delete `.dart_tool/build/cache/effects_cache.json` or run a clean build to force the cache to refresh.
- Builders rely on the annotated source placing `part '...g.dart';` at the top level. Without it, the generated file is created but unused, leading to missing symbol errors.
- `build.yaml` controls when each builder runs. Ensure new packages reference the correct builder key (`data`, `palette`, `view_kit`, `exporter`) and enable it for the desired targets.

With these builders in place, most boilerplate across state management, UI scaffolding, and exports is generated automatically, letting feature teams focus on business logic instead of wiring.
