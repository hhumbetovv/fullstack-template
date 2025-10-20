# Core Domain

Defines the shared domain contracts: entities, result types, and use-case abstractions that feature packages depend on. Import `package:core_domain/public.dart` to access the public API.

## Responsibilities
- **Entities**: Immutable value objects such as `Action`, `Failure`, `Paged<T>`, `Unit`, `AuthStatus`, and `Identifiable` that encode business concepts without framework dependencies.
- **Result system**: `Result<S, E>` with `Success` / `Error` variants, `when` helpers, and `Action` metadata for side effects.
- **Repository contracts**: Interfaces (e.g. `SessionRepository`) that the data layer implements.
- **Use-case abstractions**: `UseCase<Input, Output>`, `FlowUseCase`, and `PaginationUseCase` define how application logic is executed asynchronously.
- **Utility types**: Async result aliases (`AsyncResult<T>`), type unions, and base types used by generated code and feature modules.

## Typical consumers
- **Feature domain packages** extend the base use-case classes and implement repository interfaces for their specific modules.
- **Data layer** uses the repository contracts to provide concrete implementations (e.g. `core_data`’s `SessionRepositoryImpl`).
- **Presentation layer** relies on `Result` and entity types when reacting to use-case outcomes or rendering UI state.
- **Generators** (`gen_view_kit`) reference `Unit`, `Action`, and `Failure` when producing sealed intents/effects and base view-model classes.

## Getting started
1. Add `core_domain` as a dependency.
2. Import the public barrel: `import 'package:core_domain/public.dart';`.
3. Define repositories in your feature domain package by extending existing interfaces or creating new ones next to them.
4. Implement use cases by subclassing `UseCase` (or `FlowUseCase` / `PaginationUseCase` when applicable) and returning `AsyncResult`.

- The use case returns a `Result` wrapped in a `Future`, enabling presentation code to rely on the common `when` helpers.
- Params can be declared with `@data` to gain generated value semantics.

## How it fits with other core modules
- **Core Data** implements the repository interfaces defined here and uses domain entities to describe network results.
- **Core Presentation** relies on the result primitives and entities when updating UI state or dispatching effects.
- **Core Navigation** can react to domain-level `Action` metadata (e.g. redirects) surfaced through `Result` objects.

## Notable APIs
- `Result.when({onSuccess, onError})` simplifies branching logic in presentation layers.
- `Error<T, Failure>` and `Success<T, Failure>` constructors enforce consistent error reporting with optional `Action` metadata.
- `Paged<T>` encapsulates pagination metadata (`items`, `currentPage`, `totalPages`) for list-style features.
- `UseCase.call()` extension (provided by `core_presentation`) lets presentation code invoke use cases ergonomically.

## Editor snippets
- Snippet pack `sp-domain` bundles domain scaffolding helpers: `entity` produces an annotated value object, while `usecase`, `usecasewithparam`, `flowusecase`, and `pagusecase` wire injectable interactors with the right base classes.

## Contributing tips
- Keep domain entities free from platform-specific imports; they should remain pure Dart classes.
- When introducing new result patterns (e.g. streaming results), extend the existing abstractions instead of inventing one-off APIs.
- Document new repository contracts so data-layer developers know what to implement.
- Add unit tests around new `Result` behaviors to prevent regressions across consumers.
