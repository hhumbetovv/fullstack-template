# Core Navigation

Shared navigation utilities built on top of `auto_route`. Import `package:core_navigation/public.dart` to access routers, route constants, and transition helpers.

## Responsibilities
- **Router composition**: `BaseRouter` and the lightweight `Router` base class let feature modules register their own route trees that collapse into a single `RootStackRouter`.
- **Route naming**: `Routes` enumerates canonical path strings (splash, auth, main, QR, etc.) to keep navigation consistent across features.
- **Custom transitions**: Prebuilt route types (`FadeRoute`, `SlideUpRoute`, `InstantRoute`, `FeatureRoute`, `SheetRoute`) wrap `RouteType.custom` with project-specific animations and behaviors.
- **Navigation helpers**: Wrappers like `FeatureRoute` and `NamedRoute` give features a high-level API to push routes with arguments.

## Typical consumers
- **Root application router** extends `BaseRouter` and adds feature routers to its `routers` list (see feature/README.md for a full feature wiring example).
- **Feature presentation** packages create their own `Router` subclasses (e.g. `QrScanRouter`) and register them with the root.
- **Presentation widgets** use provided transitions to keep animations consistent without reconfiguring `AutoRoute` each time.

## Getting started
1. Add `core_navigation` as a dependency.
2. Import the barrel file: `import 'package:core_navigation/public.dart';`.
3. Implement feature routers by extending `Router` and returning a list of `AutoRoute` instances.
4. Register feature routers with a root `BaseRouter` so they contribute to the global route table.
5. Trigger navigation via helpers like `NamedRoute` or by pushing the generated auto_route pages.

## How it fits with other core modules
- **Core Presentation** widgets frequently need navigation helpers to respond to view-model effects (e.g. routing after a success).
- **Core Domain** can surface navigation-related `Action` metadata that presentation code resolves using these helpers.
- **Core Data** may expose session state that determines which router branch should be initialized.

## Transition helpers
- `FadeRoute`: Fades between pages using a shared duration constant.
- `SlideUpRoute`: Animates from the bottom, ideal for modal-like experiences.
- `InstantRoute`: Zero-duration changes for flows that should not animate.
- `FeatureRoute`: Wraps `MaterialPageRoute` to disable predictive back gestures for feature screens.
- `SheetRoute`: Launches content in a modal bottom sheet (`ModalBottomSheetRoute`).

## Contributing tips
- Keep route names descriptive and unique; update `Routes` whenever new screens are introduced.
- When adding new transition styles, encapsulate them in dedicated classes similar to `FadeRoute` so features can reuse them easily.
- Ensure feature routers remain small and focused; nested routers can be composed via the `routers` list if additional depth is required.
- Update this README when navigation patterns evolve (e.g. deep linking support) so teams know where to hook in.
