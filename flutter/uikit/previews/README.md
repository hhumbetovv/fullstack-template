# UI Components

Reusable widget library composed of design-system primitives, product widgets, managers, palettes, and theme helpers. Import `package:ui_components/public.dart` to pull everything in.

## Directory layout
- `components/foundation/`: Low-level building blocks (e.g. `Clickable`, `AnimatedVisibility`, `MeasureSize`, list builders). These focus on behaviour and composability without enforcing product styling. Use them when you need interaction patterns or layout helpers that can be restyled easily (see uikit/foundation/README.md for the tokens they rely on).
- `components/product/`: Branded widgets such as `UiScaffold`, `UiAppBar`, `UiButton`, `UiTextField`, and list items. They glue together foundation components with palette tokens to deliver the final product look and feel.
- `managers/`: Stateful helpers (`SnackBarManager`, `BottomSheetManager`) that centralize overlay presentation logic. They use Flutter’s global keys from `common_presentation` and palette/theme tokens to render consistent surfaces.
- `palette/`: Generated classes (via `gen_palette`) representing color, typography, and component states. Files ending with `.g.dart` are generated; do not edit them manually. Examples include `ButtonPalette`, `NavigatorPalette`, `TextFieldPalette`, and their accompanying state enums.
- `theme/`: Theme composition utilities. `BaseTheme` defines the abstract contract, `LightTheme` provides the concrete implementation, `Styles` contains typography/text style references sourced from `ui_foundation`’s `FontFamily` constants, and `ThemeExtensions` bridges palettes into Flutter’s theme system.

## Foundation vs product components
- **Foundation** widgets are meant to be reusable across products or features. They provide behaviors such as click handling, collapsible content, hero wrappers, pagination builders, and image utilities. Style them via palettes or by wrapping them inside product components.
- **Product** widgets assume the full design system. They expose high-level APIs (e.g. `UiButton.primary`, `UiTextField.standard`) and should be the default choice in feature code for consistency. If a new pattern emerges, prototype it in foundation, then wrap it in a product widget once the design is finalized.

## Managers
- `SnackBarManager.showSuccess|showError|showInfo` displays branded snackbars using the global `messengerKey`. Configure `CommonPresentationConfig` before use.
- `BottomSheetManager.show` presents modal sheets with project styling and safe-area handling. Both managers respect the theme/palette to ensure overlays feel native.

## Palette structure
- Palette classes under `palette/` are generated from annotated definitions and implement lerp/copy behaviour. Each palette groups related tokens: `ButtonPalette` for button backgrounds and text colors, `NavigatorPalette` for navigation surfaces, `TextFieldPalette` for input states, etc.
- State enums (`ButtonState`, `TextFieldState`) describe variations (normal, pressed, disabled, error). Generated extensions provide easy access to specific states (e.g. `palette.button.primary.enabled`).
- When adding a new palette, update the annotated source, run `build_runner`, and avoid editing generated files directly.

## Theme helpers
- `BaseTheme` and `LightTheme` compose palettes and design tokens into Flutter’s `ThemeData`.
- `palette/palette.dart` exposes the root theme palette, allowing runtime access via `context.palette` (see `theme/build_context.dart`).
- `styles.dart` collects reusable `TextStyle` definitions (e.g. `Styles.gothamHeader2Bold`) and pulls font names from `ui_foundation`’s `FontFamily`. Keep typography updates centralized here. When adding fonts, register them in `pubspec.yaml` and update `uikit/foundation/lib/src/constants/font_family.dart` so the constants stay aligned.
- `theme_extensions.dart` registers palette classes as `ThemeExtension`s, enabling widgets to read palette values from `Theme.of(context)`.

## Editor snippets
- Snippet pack `sp-uikit` focuses on palette scaffolding: `palettevar` retrieves the active palette from context and `palette` sets up a `@palette` class with the expected `part` directive.

## Usage guidelines
- Feature code should prefer product components (`UiButton`, `UiScaffold`) and palette-aware helpers (`context.palette`) to maintain consistency.
- Use foundation components when building new product widgets or when no branded alternative exists yet.
- When introducing new component families, update this README and the public export to keep consumers informed.
- Rerun `dart run build_runner build` after changing palette annotations so generated files stay in sync.
