# Lexi Mobile — Implementation Log

> Permanent record of what was actually built. Never deleted, only appended.

---

## Log

## 2026-11-14 — Phase 1: Project Setup

- [x] Added `flutter_bloc 9.1.1`, `equatable 3.0.0`, `get_it 9.3.0`, and `http 1.6.0`
- [x] Added dev dependencies `bloc_test 10.0.0` and `mocktail 1.0.5`
- [x] Created the global-layer structure for `core/`, `data/`, `domain/`, and `presentation/`
- [x] Added `AppConfig` with the production API URL, `API_BASE_URL` override, and 15s/60s timeouts
- [x] Added the sealed `AppFailure` hierarchy and backend error-code mapping
- [x] Added `ApiClient` with envelope parsing, pagination metadata, per-request timeouts, and data-layer exceptions
- [x] Added the domain `PaginatedResult<T>` wrapper
- [x] Added manual GetIt registrations for `http.Client` and `ApiClient`
- [x] Added the debug error logger
- [x] Replaced the counter app with the Lexi shell, light-first theme, and placeholder page
- [x] Added built-in `Navigator` routing with centralized named routes and `onGenerateRoute`
- [x] Added Android `INTERNET` permission and debug-only cleartext HTTP

## Screens Implemented

- Placeholder shell — app bar and centered Lexi placeholder content

## API Integration

- No endpoints connected yet
- `ApiClient` foundation is ready for the first data source

## Tests

- `ApiClient`: success envelope, error envelope, non-2xx response, malformed JSON, timeout, POST construction, and empty 204
- Failure mapper: validation, not found, AI not ready, duplicate, conflict, timeout, network, parse, and unknown errors
- App config defaults and app shell smoke test
- Result: 21 tests pass

## Verification

- `flutter analyze` — no issues
- `flutter test` — 21 tests pass
- `flutter build apk --debug` — succeeded
- App shell rendered by the widget test; no Android device or emulator was connected for a manual launch

## Notes

- Light-first theme uses `#F7F6F2` with the `#6C63FF` accent; dark mode and glassmorphism are deferred
- No startup warm-up call is made
- No third-party routing package is used
- No feature screens, models, entities, use cases, or blocs were added
- No git repository is initialized, so no commit was created

