# Core Data

Provides the data-layer building blocks used by the rest of the stack: network configuration, local persistence, DTOs, and repository glue. Import `package:core_data/public.dart` to access the full surface.

## Responsibilities
- **Network setup**: `ApiBaseOptions`, `Endpoint`, `Endpoints`, and `NetworkModule` configure Dio clients, interceptors, and base URLs.
- **Remote data sources**: Retrofit interfaces (e.g. `SessionApi`) describe REST endpoints and return `NetworkResponse<T>` objects.
- **Local data sources**: Shared preferences and secure storage services expose typed APIs for caching tokens, flags, and lightweight state.
- **Repository implementations**: Classes such as `SessionRepositoryImpl` combine local and remote data to satisfy domain contracts.
- **Safe wrappers**: Helpers (`safeCall`, `safeRequest`, `safeMapperCall`, `safeUnitCall`) standardize error handling and translate responses into `Result` objects.
- **Model and mapper layer**: DTOs (`SessionRequest`, `NetworkResponse`, `PagedModel`, etc.) plus mapper extensions bridge remote data with domain entities.

## Internal consumers
- **Core Domain**: Repository contracts live there; this package supplies the concrete implementations and DTO-to-entity mappers.
- **Core Presentation**: Expects repositories to return `Result` objects with `Failure`/`Action` metadata for consistent UI handling.
- **Core Navigation**: Reads session or auth state exposed by repositories to decide initial routes or redirects.

## Getting started
1. Add `core_data` as a dependency in your package.
2. Ensure the micro package is initialized when bootstrapping dependency injection:
   ```dart
   @InjectableInit.microPackage()
   void initMicroPackage() {}
   ```
   Include the generated `CoreDataPackageModule` in your root `GetIt` initialization or call `initMicroPackage()` from the micro package.
3. Import the barrel file: `import 'package:core_data/public.dart';`.
4. Inject the required services (`SharedPrefsService`, `SecureStorageService`, `Dio`, repositories) wherever needed.

## How it fits with other core modules (see feature/README.md for end-to-end usage)
- **Core Domain** supplies repository contracts (`SessionRepository`, etc.) that implementations here fulfill.
- **Core Presentation** consumes the async `Result` objects produced by safe-call helpers, enabling consistent UI handling.
- **Core Navigation** often pairs with repositories when routing depends on session state or other data exposed by this layer.

## Notable modules
- `src/common/`: Shared safe-call helpers.
- `src/core/`: Global network configuration.
- `src/datasource/`: Remote APIs (`retrofit`) and local persistence services.
- `src/interceptors/`: Dio interceptors (logging, auth, etc.).
- `src/module/`: Injectable modules tying everything together.
- `src/repository/`: Concrete repository implementations.

## Editor snippets
- Snippet pack `sp-data` supplies quick-start templates: `requestmodel` / `responsemodel` generate JSON serializable DTOs, `api` creates a Retrofit service shell, `store` sets up an ObjectBox wrapper, and `repository` seeds an injectable repository implementation.

## Contributing tips
- Keep DTOs and mappers in sync; annotate new models with `json_serializable` for consistency.
- Prefer adding new endpoints via Retrofit interfaces and let generators produce the `.g.dart` client code.
- Reuse the safe-call helpers to ensure all repositories return `Result` types with meaningful `Failure` information.
- Update this README when new subsystems (e.g. caching, websockets) are added so other teams understand the available primitives.
