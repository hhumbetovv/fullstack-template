# Generator Plugins

All code generators live under `generator/plugins/`. Each package is a standalone
`dart` package with its own `pubspec.yaml`, `build.yaml`, and tests. They share
infrastructure by depending on `gen_core` and `processor/public.dart`.

```
generator/plugins/
├── assets/      # Asset enum/icon font builder
├── data/        # @data value object builder
├── exporter/    # public.dart export aggregator
├── palette/     # @palette/@rootPalette builders (reusing gen_data)
└── view_kit/    # @view/@viewModel/@provider builders
```

## Adding a new plugin

1. `mkdir generator/plugins/<name>` and scaffold a Dart package (`pubspec.yaml`,
   `analysis_options.yaml`, `lib/` with builder entrypoint).
2. Depend on `gen_core` for `BaseBuilder`/`BaseFactory` and on
   `processor/public.dart` for annotations/config DTOs.
3. Implement resolvers/factories as described in `generator/core/README.md`.
4. Update the workspace list in the root `pubspec.yaml` so `dart pub get`
   includes the new package.
5. Reference the builder from consuming packages via `build.yaml` as needed.

Each plugin should keep large factories/resolvers split into components (see
`view_kit` for examples) to keep maintenance manageable.
