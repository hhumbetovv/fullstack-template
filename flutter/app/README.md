# App Module

Hosts the Flutter application shell: global configuration, dependency injection, router composition, and the root widget tree. Read this first when wiring new features into the app.

## Environment
- Place `.env.<flavor>` files inside `app/` (used by platform builds) and keep the root copies in sync.
- `AppConfig.setup()` calls `Environment.initialize()` to load the appropriate file for the active flavor.

## Boot sequence
1. `main.dart` calls `AppConfig.setup()` before `runApp`.
2. `AppConfig.setup()` (see common/shared/README.md and common/presentation/README.md) initializes:
   - `CommonSharedConfig` (console formatter, environment loading).
   - `CommonPresentationConfig` (snack bar styling using UI foundation tokens).
   - Dependency injection via `configureDependencies()`.
3. `runApp` wraps the app in `AppProviderScope`, registering global providers (session, etc.).
4. `App` builds a `MaterialApp.router` with theming from `ui_components` / `ui_foundation`, global keys from `common_presentation`, and router config from `AppRouter`.

## Dependency injection
- `config/injectable.dart` owns the GetIt setup. It imports micro packages from core and feature layers and declares them in `externalPackageModulesBefore` so their registrations load first.
- When a new feature exposes a presentation micro package (see feature/README.md), add its generated module here.
- Call `configureDependencies()` only via `AppConfig.setup()` to keep initialization in one place.

## Router composition
- `config/router.dart` extends `BaseRouter` (see core/navigation/README.md). It imports feature routers (`SplashRouter`, `MainRouter`, `ExampleRouter`, etc.) and returns them from `routers`.
- To expose a new screen:
  1. Export the route name in `core_navigation/lib/src/core/routes.dart` (see core/navigation/README.md).
  2. Add the feature router to `AppRouter.routers`.
  3. Ensure the feature presentation package registers its router in its own `router.dart` (see feature/README.md).
- `App` supplies a `deepLinkBuilder` that forwards deep links to the splash route. `SplashViewModel` (in the splash feature) is responsible for analyzing the link and navigating to the correct destination (see feature/README.md).

## Root view & system chrome
- `RootView` wraps every screen with:
  - `AnnotatedRegion<SystemUiOverlayStyle>` to control status/navigation bar colors.
  - A `Scaffold` that uses palette colors (`context.palette` → uikit/components/README.md) and dismisses the keyboard on tap.
  - Optional Konami gesture when `Console.isEnabled` to expose the console route.

## Theming
- `MaterialApp.router` references `BaseTheme.light.data` (see uikit/components/README.md and uikit/foundation/README.md) for consistent styling.
- Scroll behavior is normalized via `AppScrollBehavior` to remove overscroll glow.

## Providers
- `AppProviderScope` currently registers `SessionProvider` from session_presentation. Add new global providers here only when multiple screens need feature-scoped state from the root.

## Adding a new feature end-to-end
1. Follow the guidelines in feature/README.md to create data/domain/presentation packages and regenerate code.
2. Export the feature presentation micro package’s module (`ExamplePresentationPackageModule`) and add it to `externalPackageModulesBefore` in `config/injectable.dart`.
3. Import the feature router in `config/router.dart` and append it to the `routers` list.
4. Export required route strings in `core_navigation`.
5. Ensure the feature handles deep-link intents inside its splash/onboarding logic if needed.

With these steps, the app module remains the thin composition root that wires infrastructure and features together.
