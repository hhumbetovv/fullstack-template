# Feature Module Linter

Enforces import boundaries for single-module features structured as:

- `lib/data/`
- `lib/domain/`
- `lib/presentation/`

Rules:

- No relative imports (`./`, `../`) under the three folders.
- No `src/` imports from the same package.
- Only allow self-package imports via top-level barrels: `data.dart`, `domain.dart`, `presentation.dart`.
- Cross-layer dependencies:
  - data: must not import presentation.
  - domain: must not import data or presentation.
  - presentation: must not import data.

## Run

From repo root:

```
fvm dart run linter
```

Options:

- `-r, --root <path>`: override workspace root to scan.
- `-v, --verbose`: verbose output.

## Module configuration

Define feature-specific rules in `module.yaml` under a `lint` key. Example:

```
lint:
  feature_layers:
    data:
      - retrofit
      - dio
      - json_annotation
    domain:
      - meta
    presentation:
      - auto_route
      - flutter
```

Each layer lists the packages that code inside that folder may import. Layers omitted from the map remain unrestricted.

### Includes and overrides

`lint` supports the same include syntax as `build`:

```
lint:
  include:
    - configs/lint/base.yaml
    - configs/lint/network.yaml
  feature_layers:
    data:
      - retrofit
      - dio
```

Include entries are merged in order. Entries can be relative paths or maps with `path`/`raw`. Additional inline keys override the merged result.
