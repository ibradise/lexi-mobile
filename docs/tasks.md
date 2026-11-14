# Lexi Mobile — Implementation Tasks

> Current phase only. See `docs/architecture.md` for the approved architecture.

---

## Phase 1: Project Setup

### Dependencies

- [x] Add latest stable runtime dependencies: `flutter_bloc`, `equatable`, `get_it`, `http`
- [x] Add latest stable dev dependencies: `bloc_test`, `mocktail`
- [x] Remove the default counter app code and test

### Structure

- [x] Create the global-layer folder structure:
  - `lib/core/config/`
  - `lib/core/di/`
  - `lib/core/network/`
  - `lib/core/error/`
  - `lib/core/utils/`
  - `lib/data/datasources/`
  - `lib/data/models/`
  - `lib/data/repositories/`
  - `lib/domain/entities/`
  - `lib/domain/repositories/`
  - `lib/domain/usecases/`
  - `lib/presentation/bloc/`
  - `lib/presentation/pages/`
  - `lib/presentation/widgets/`
  - `lib/presentation/navigation/`

### Foundation

- [x] Add `AppConfig` with production API base URL, `API_BASE_URL` `--dart-define` override, and standard/AI timeout constants
- [x] Implement the sealed `AppFailure` hierarchy
- [x] Implement `ApiClient` with JSON envelope parsing, pagination meta, per-request timeouts, and data-layer exceptions
- [x] Implement the data-layer exception to `AppFailure` mapper
- [x] Add the domain `PaginatedResult<T>` wrapper
- [x] Set up manual GetIt registrations for `http.Client`, `ApiClient`, and future layers
- [x] Add a debug logger utility for unexpected exceptions
- [x] Replace the counter screen with the Lexi app shell and light-first theme in `lib/core/config/app_theme.dart` (off-white background `#F7F6F2`, purple accent `#6C63FF`, dark text)
- [x] Set up built-in `Navigator` with centralized named routes in `presentation/navigation/` and `onGenerateRoute` for typed arguments

### Platform

- [x] Add the Android `INTERNET` permission to the main manifest
- [x] Allow cleartext HTTP in the debug manifest for local API development only

### Tests

- [x] Test `ApiClient`: success envelope, error envelope, non-2xx response, malformed JSON, timeout, and request construction
- [x] Test the exception-to-failure mapper for every mapped backend code
- [x] Replace the default widget test with an app shell smoke test

### Documentation

- [x] Update `docs/architecture.md` if the implementation differs from the approved design
- [x] Append the completed setup work to `docs/IMPLEMENTATION.md`

### Verification

- [x] `flutter analyze` passes with no issues
- [x] `flutter test` passes
- [x] `flutter build apk --debug` succeeds
- [x] App launches with the production API configuration

---

Do not start the next phase, clear this file, or commit until the user approves the
completed setup.
