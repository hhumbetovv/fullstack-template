# Feature Modules Overview

Every feature follows the same layering pattern—data, domain, and presentation—so new modules behave consistently. The Example feature outlined below serves as a blueprint; replace the names with your own feature-specific ones.

```
feature/main/feature/example
├── data        # Remote APIs, DTOs, repository implementation
├── domain      # Repository contract and use cases
└── presentation# Screens, providers, generated widgets
```

## Domain layer (`example/domain`)
- **Repository contract**: Abstract interface (`ExampleRepository`) defining the operations used by presentation code. Return `AsyncResult<T>` types.
- **Use cases**: Classes such as `SubmitExampleUseCase` extending `UseCase<Input, Output>`. Annotate with `@injectable` so they can be resolved in view-models. Input parameter objects (`SubmitExampleUseCaseParams`) should be declared with `@data` for immutability and copy helpers.
- **Micro package hook**: Mirror the data layer by exposing `@InjectableInit.microPackage()` in `example/domain/lib/init.dart`. Presentation code should invoke both data and domain initializers during startup.

## Data layer (`example/data`)
- **API client**: Retrofit interface (`ExampleApi`) annotated with endpoint definitions. Declare it with `@injectable` so Dio instances are resolved from `core_data`.
- **Request/response models**: DTOs (`ExampleRequest`, `ExampleResponse`) generated via `json_serializable`. Keep them as close as possible to backend payloads.
- **Mappers**: Extension methods under `data/src/mapper` to translate DTOs into domain entities and to build request bodies from domain parameters.
- **Repository implementation**: Concrete class (`ExampleRepositoryImpl`) satisfying the domain contract. Wrap network calls with `safeMapperCall` / `safeCall` to emit `Result` objects. Register it with `@LazySingleton(as: ExampleRepository)` so injectable can wire it automatically.
- **Micro package hook**: Expose `@InjectableInit.microPackage()` in `example/data/lib/init.dart` and call `initMicroPackage()` from the presentation module so new services join the main dependency graph.

## Presentation layer (`example/presentation`)
The presentation package owns screens, providers, and generated view/view-model code.

### Directory layout
```
presentation/lib/src
├── screen_a/          # Screen module (state, view, view-model, components)
├── screen_b/
├── shared_provider/   # Providers exposing shared view-models
└── router.dart        # Feature router
```

Each screen module typically contains:
- `state.dart`: `@data` state definition. Include an `isLoading` field when you plan to use `runWithLoading`.
- `view_model.dart`: Annotated with `@viewModel`. Define intent methods with `@intent` and emit side effects with `postEffect(...)`.
- `view.dart`: Annotated with `@view`. Dispatch intents using generated helpers (e.g. `ExampleIntent.submit().dispatch(context)`) and handle effects via `@effect` methods.
- `components/`: Optional folder for reusable widgets specific to the screen.

Providers (`@provider`) live under `shared_provider/` (or next to the screen if they are tightly coupled). They scope view-model instances so multiple screens can reuse the same logic.

### Generated helpers (see core/presentation/README.md for runtime details)
`gen_view_kit` produces additional conveniences:
- `exampleSelect<Value>(context, selector)` helpers for selecting derived state.
- `exampleState(context, {watch: true/false})` style helpers to read the entire view-model state.
- Sealed intent/effect classes (`ExampleIntent.*`, `ExampleEffect.*`) with `dispatch(context)` extensions.
Always regenerate code with `dart run build_runner build -r` after changing annotations.

### Intents, effects, and providers
- Use `@intent` on internal view-model methods. Generated intent constructors mirror the method names.
- Use `@effect` on view methods that should react to effects from the local view-model. To subscribe to another view-model’s effects, annotate with `@Effect(from: [OtherViewModel])`.
- Providers expose a `buildWithChild` override; wrap child widgets so they inherit the provider’s view-model scope.

### Navigation (see core/navigation/README.md for shared route utilities)
1. Define a router in `presentation/router.dart`:
   ```dart
   final class ExampleRouter extends Router {
     @override
     List<AutoRoute> get routes => [
       FeatureRoute(
         name: Routes.example,
         builder: (_, __) => const ExampleScreen(),
       ),
       SheetRoute(
         name: Routes.exampleSheet,
         builder: (_, data) => ExampleSheet(data.args),
       ),
     ];
   }
   ```
2. Register it with the app module router: add `ExampleRouter()` to the root `BaseRouter` implementation inside the app package. (Core navigation only hosts route name constants, not router wiring.)
3. Export new route names from `core_navigation/lib/src/core/routes.dart` so features can navigate using `Routes.example` etc.
4. Handle deep links in a central place (commonly `SplashViewModel`). Parse the incoming URI, determine the target feature route, and dispatch a navigation effect (`postEffect(ExampleEffect.openDeepLink(targetRoute))`). The feature view should react to the effect and call `context.navigateTo(...)`.

### Dependency initialization
- Presentation modules also expose `@InjectableInit.microPackage()` (see `presentation/lib/init.dart`). Call this during application bootstrap **after** data/domain initializers so view-model dependencies are available. Declare external modules from the data and domain packages so injectable replays their registrations:
```dart
@InjectableInit.microPackage(
  externalPackageModulesBefore: [
    ExternalModule(ExampleDataPackageModule),
    ExternalModule(ExampleDomainPackageModule),
  ],
)
void initMicroPackage() {}
```
- Ensure `main()` (or the app-level composition root) invokes:
  ```dart
  Future<void> configureDependencies() async {
    await coreData.initMicroPackage();
    await coreDomain.initMicroPackage();
    await exampleData.initMicroPackage();
    await exampleDomain.initMicroPackage();
    await examplePresentation.initMicroPackage();
  }
  ```

## Development checklist
1. Define the repository contract and use cases in the domain layer and annotate with `@injectable`.
2. Implement the data layer repository, API clients, and DTO mappers. Register the micro package initializer.
3. Build the presentation layer:
   - State (`@data`), view-model (`@viewModel`), view (`@view`), and optional provider (`@provider`).
     - Update `router.dart` with new screens and add corresponding route names to `core_navigation`.
   - Use generated helpers (`exampleSelect`, `exampleState`, intent dispatchers) to avoid manual boilerplate.
4. Register micro packages (data, domain, presentation) in the app bootstrap.
5. Run `dart run build_runner build -r` to regenerate all `.g.dart` files.
6. Add tests for repositories, use cases, and key presentation flows (intent/effect handling, navigation).

## Editor snippets
- Snippet pack `sp-view-kit`: `state`, `viewmodel`, `view`, `provider`, and `intent` prefixes scaffold annotated presentation files with the correct imports, part directives, and base classes.
- Snippet pack `sp-module`: `initdi` seeds a micro-package initializer and `initrouter` builds a router skeleton aligned with `BaseRouter`.
- Snippet pack `sp-data`: `requestmodel`, `responsemodel`, `api`, `store`, and `repository` jump-start the feature data layer; tweak the generated placeholders to match your feature.
- Snippet pack `sp-domain`: `entity`, `usecase`, and related prefixes accelerate domain contracts and interactors.
- Snippet pack `sp-core-yaml`: `initpresentation`, `initdomain`, `initdata`, and the `build*` variants populate `pubspec.yaml` and `build.yaml` templates for new micro packages.

Following this pattern keeps features consistent and makes it easier for teammates to navigate and extend the codebase.
