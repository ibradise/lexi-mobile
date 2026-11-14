# Lexi Mobile — Technical Architecture

> Current architecture and code structure for the Lexi Flutter app.

---

## Overview

The mobile app uses Clean Architecture with **global layers**. Features are built as
vertical slices through the same `data/`, `domain/`, and `presentation/` layers rather
than as isolated feature modules.

The `domain/` layer is pure Dart. It must not import Flutter, `http`, or any data-layer
code.

---

## Tech Stack

| Concern | Choice |
|---------|--------|
| Framework | Flutter |
| Language | Dart |
| State management | Bloc (`flutter_bloc`) — BLoC and Cubit |
| Dependency injection | Manual `get_it` |
| Networking | `http` through a centralized `ApiClient` |
| Error handling | Exceptions + `AppFailure` |
| Data mapping | Data models separate from domain entities |
| Operations | One use case per meaningful application operation |
| Testing | `flutter_test`, `bloc_test`, `mocktail` |
| Navigation | Flutter built-in `Navigator` with centralized named routes |
| Persistence | None in MVP |

---

## Project Structure

```
lib/
├── core/
│   ├── config/
│   ├── di/
│   ├── network/
│   ├── error/
│   └── utils/
│
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│
├── presentation/
│   ├── bloc/
│   ├── pages/
│   ├── widgets/
│   └── navigation/
│
└── main.dart
```

No feature subfolders are used. If the app grows enough to justify them, the structure
can be reorganized later.

---

## Dependency Rule

```
presentation ──→ domain
data         ──→ domain
domain       ──→ core/error + pure Dart only
main/core/di ──→ all layers
```

- `domain/` must not import `data/`, `presentation/`, Flutter, or `http`.
- `presentation/` must not import `data/` implementations.
- `data/` may import `domain/` and `core/network/`.
- `core/di/` is the composition root and may import every layer.

---

## Layer Responsibilities

| Layer | Responsibilities | Must not |
|-------|------------------|----------|
| `ApiClient` (`core/network`) | Base URL, headers, JSON encode/decode, envelope parsing, timeouts, transport exceptions | Know endpoints, models, or business rules |
| `RemoteDataSource` (`data/datasources`) | Endpoint paths, query parameters, request bodies, JSON → models | Know entities or `AppFailure` |
| `Repository` (`data/repositories`) | Implement domain interfaces, orchestrate data sources, models → entities, exceptions → `AppFailure` | Contain UI or HTTP details |
| `UseCase` (`domain/usecases`) | One meaningful application operation, input validation, call repository interfaces | Know HTTP, JSON, Flutter, or BLoC |
| BLoC / Cubit (`presentation/bloc`) | State transitions, call use cases, catch `AppFailure` | Call `ApiClient`, parse JSON, or contain UI code |
| Widgets (`presentation/`) | Render state, dispatch events | Contain business logic or call repositories |

Data sources are concrete classes per domain area. Only domain repositories need
abstract interfaces.

Models expose `toEntity()` mappers. Entities never expose JSON serialization.

---

## Request Flow

```
Widget
  → BLoC / Cubit
  → UseCase
  → Repository interface
  → Repository implementation
  → RemoteDataSource
  → ApiClient
  → http.Client
```

---

## Error Handling

### Failure hierarchy

```
AppFailure (sealed, implements Exception)
├── NetworkFailure
├── ValidationFailure
├── NotFoundFailure
├── AiNotReadyFailure
├── ConflictFailure
│   └── DuplicateWordFailure
└── UnknownFailure
```

### Rules

- `ApiClient` throws data-layer exceptions such as `ApiException`.
- Repositories translate data-layer exceptions into `AppFailure`.
- Only repositories construct `AppFailure`.
- BLoCs catch `AppFailure` and emit error states.
- Widgets display failure messages; they never inspect HTTP status codes.
- Unexpected exceptions are logged with their stack trace and mapped to
  `UnknownFailure`.
- Backend validation messages are safe to display. Network, parse, and server
  failures use friendly app-level messages.

### Backend error codes

| Backend code | Failure |
|--------------|---------|
| `VALIDATION_ERROR`, `INVALID_EXERCISE` | `ValidationFailure` |
| `NOT_FOUND` / HTTP 404 | `NotFoundFailure` |
| `AI_NOT_READY` | `AiNotReadyFailure` |
| `DUPLICATE_WORD` | `DuplicateWordFailure` with existing word id |
| `CONFLICT` / HTTP 409 | `ConflictFailure` |
| `INTERNAL_ERROR` / HTTP 5xx | `UnknownFailure` |
| Network, timeout, or parse error | `NetworkFailure` or `UnknownFailure` |

---

## API Integration

> Endpoint-level request and response details live in
> [`docs/api-contract.md`](api-contract.md). That file is canonical for payloads,
> status codes, limits, and error codes. This section covers mobile integration
> patterns only.

- Production base URL: `https://lexi-backend-z0zy.onrender.com/api`
- Override with `--dart-define=API_BASE_URL=...`
- Android emulator: `http://10.0.2.2:3001/api`
- All responses use the envelope:

```json
{
  "success": true,
  "data": {},
  "error": null,
  "meta": null
}
```

- `ApiClient` parses the envelope and returns `ApiResponse { data, meta }`.
- Paginated endpoints return `meta { page, limit, total, totalPages }`.
- The repository maps pagination meta into a domain `PaginatedResult<T>`.
- Timeouts are per operation:
  - Standard requests: 15 seconds.
  - AI-dependent requests: 60 seconds to tolerate Render cold starts.
- No startup warm-up call is made. The first request may be slow while the backend
  wakes.

### AI readiness

The backend generates AI content synchronously for up to 8 seconds, then continues in
the background.

| Endpoint | Response |
|----------|----------|
| `POST /api/vocabulary` (single) | `201`; ready when `aiModel` is present, otherwise pending |
| `POST /api/vocabulary` (bulk) | `202`; added words are `PENDING` |
| `GET /api/vocabulary` | Includes `aiReady` |
| `GET /api/review/today` | Queue items include `aiReady` |
| `GET /api/vocabulary/:id` | Includes `aiModel` and `aiData` |
| `GET /api/vocabulary/:id/exercises` | `409 AI_NOT_READY` until ready |

There is no terminal `FAILED` state. Words that exhaust background retries remain
pending. The client should poll with backoff, then offer a retry through
`POST /api/vocabulary/:id/regenerate-ai`.

---

## Dependency Injection

Manual `get_it` registration in `core/di/`.

| Component | Registration |
|-----------|--------------|
| `http.Client` | Singleton, disposed on reset |
| `ApiClient` | Lazy singleton |
| Data sources | Lazy singleton |
| Repositories | Lazy singleton |
| Use cases | Lazy singleton |
| BLoCs / Cubits | Factory |

Rules:

- Dependencies are injected through constructors.
- BLoCs must not read from GetIt directly.
- `getIt.reset()` is called in test teardown.
- The HTTP client is closed when dependencies are reset.

---

## State Management

- Use `Bloc` for screen-level state and event handling.
- Use `Cubit` only for trivial local state.
- Events and states extend `Equatable`.
- Each BLoC receives its use cases through its constructor.
- Widgets dispatch events and render states only.

---

## Testing

| Layer | Approach |
|-------|----------|
| `ApiClient` | `MockClient` from `package:http/testing.dart` |
| Remote data sources | Mock `ApiClient` |
| Repositories | Mock data sources; verify mapping and failure translation |
| Use cases | Mock domain repository interfaces |
| BLoCs / Cubits | `bloc_test` with mocked use cases |
| Screens | Widget tests with mocked state |

`mocktail` is used for fakes and mocks. Tests reset GetIt in teardown.

---

## Navigation

Navigation uses Flutter's built-in `Navigator` with centralized named routes.
Route definitions and navigation helpers live in `presentation/navigation/`, using
`onGenerateRoute` for typed route arguments.

Do not add a third-party routing package.

---

## Theming

- Light theme is the default, defined in `lib/core/config/app_theme.dart`.
- Off-white background: `#F7F6F2` (not pure white).
- Purple accent: `#6C63FF`.
- Dark text and surfaces for contrast.
- Material 3 color scheme, typography, and shared tokens.
- No dark mode in the initial setup.
- Glassmorphism cards and transitions are added as UI features are built.
- Widgets must use theme values and shared tokens; no hardcoded colors.
- Async screens provide loading, empty, and error states with retry actions.
