# UI Foundation

Design tokens and constants shared across the UI layer. Import `package:ui_foundation/public.dart` to access the full set.

## Token families
- **Colors (`AppColors`)**: Brand palettes grouped into numeric scales (`orange50`–`orange900`, `black50`–`black900`, `neutral50`–`neutral900`) plus semantic aliases (`orange`, `neutral`, `white`, `shadow`, `red`, `green`, `blue`, `transparent`). Keep names aligned with the design system so palette generators and theme extensions stay consistent.
- **Spacing & dimensions (`AppDimens`, `AppSpacing`, `AppPadding`)**: Single source for layout sizes (`min = 2`, `micro = 4`, `small = 8`, `medium = 12`, `large = 16`, `macro = 20`, `max = 24`). `AppSpacing` and `AppPadding` wrap these values to avoid scattering raw numbers across widgets.
- **Radius & curves (`AppRadius`, `AppCurves`)**: Corner radii and animation curves that match UX specs; reused by buttons, cards, dialogs, and transition builders.
- **Durations (`AppDuration`)**: Standard motion timings (`fast`, `medium`, `slow`, `fade`, etc.) referenced by route transitions and component animations.
- **Defaults (`AppDefaults`)**: Baseline configuration values applied by higher-level widgets (e.g. scaffold padding, keyboard behaviour).
- **Hero tags (`AppHeroTags`)**: Common hero identifiers to prevent mismatched strings when coordinating cross-screen animations.
- **Assets (`AppIcons`, `AppImages`)**: Enums mirroring the `assets/icons` and `assets/images` directories. Examples: `AppIcons.qrCode` → `assets/icons/qr-code.svg`, `AppImages.titleLogo` → `assets/images/title-logo.png`. Use these instead of hard-coded paths.

## Naming alignment
- Color names should match brand terminology; avoid adding raw hex-labelled constants. When design renames a tone, update the corresponding constant and downstream palettes.
- Spacing identifiers correspond to the dimension table agreed with design. If a new size is introduced, add it here first so padding/spacing helpers remain in sync.
- Asset enums must follow the file names exactly (kebab-case in the asset, camelCase in the enum). When adding new assets, update both the enum and the asset list to keep pipelines happy.

## Relationship with other modules
- **UI Components** consumes every token family to build branded widgets without redefining constants.
- **Core presentation & navigation** reference duration and curve tokens for consistent transitions.

## Working guidelines
- Add or rename tokens only after coordinating with design; this package is the canonical source of truth.
- Prefer referencing these constants everywhere else in the codebase—do not duplicate numeric values or hex strings in feature code.
- After adding icons/images, run the asset bundling step (if required) and ensure the enum exposes all necessary getters (`svg`, `png`, `jpg`).
- Update this README whenever new token families are introduced so other teams know how to adopt them.
