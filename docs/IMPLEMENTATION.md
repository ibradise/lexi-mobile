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
- Git repository initialized after this entry; Phase 1 scaffolding was committed in `e10e41c`

## 2026-11-17 — Phase 2: Add Words

- [x] Added `VocabularyWord`, `AddedWord`, `BulkAddResult`, and `AddWordParams` domain types
- [x] Added the `VocabularyRepository` interface with single and bulk add operations
- [x] Added `AddWord` and `AddWords` use cases with input trimming and optional-field normalization
- [x] Added models for ready/pending single-word responses and bulk add summaries
- [x] Added `VocabularyRemoteDataSource` for `POST /api/vocabulary`
- [x] Used the 60-second AI timeout for single add and the 15-second standard timeout for bulk add
- [x] Added `VocabularyRepositoryImpl` with model-to-entity mapping and `AppFailure` translation
- [x] Registered the data source, repository, use cases, and `AddWordBloc` factory in GetIt
- [x] Added `AddWordBloc` with single submit, bulk submit, and reset events
- [x] Added idle, submitting, single success, bulk success, and failure states
- [x] Replaced the placeholder screen with a minimal `HomePage` and Add Words CTA
- [x] Added the `/add-word` route and route-level bloc provider
- [x] Added `AddWordsPage` with single/bulk mode switching and theme-based styling
- [x] Added local validation for required words, the 100-character limit, and non-empty bulk input
- [x] Added loading, duplicate, validation, network, retry, success, and add-another UI states
- [x] Added unit, model, data source, repository, use case, bloc, page, and app shell tests

## Screens Implemented (mobile)

- Home — minimal landing screen with the "Add words" CTA; dashboard content is planned
- Add Words — single and bulk entry, AI ready/pending feedback, bulk summary, retry, and reset

## API Integration

- `POST /api/vocabulary` with `{ word, ... }` — single add; 60-second AI timeout
- `POST /api/vocabulary` with `{ words: [...] }` — bulk add; 15-second standard timeout
- Single add parses `aiModel` to determine AI ready/pending status
- Bulk add displays added, duplicate, and invalid counts from the `202` response
- No AI polling is performed on the Add Words screen

## Tests

- Model mapping: ready/pending single responses and bulk summaries
- Remote data source: endpoint path, request bodies, omitted nulls, and timeouts
- Repository: entity mapping and failure translation
- Use cases: trimming and repository delegation
- Bloc: single success, pending, duplicate failure, bulk success, and network failure
- Add Words page: validation, mode switching, pending result, reset, retry, and bulk summary
- App shell: home CTA and navigation to Add Words
- Result: 49 tests pass

## Verification

- `dart format --output=none --set-exit-if-changed lib test` — no changes
- `flutter analyze` — no issues
- `flutter test` — 49 tests pass
- `flutter build apk --debug` — succeeded
- Build output: `build/app/outputs/flutter-apk/app-debug.apk`
- No Android device or emulator was connected for a manual launch

## Notes

- No new dependencies were added
- The Home screen is a Phase 2 landing screen, not the full dashboard
- Source URL is accepted as free text and is not validated locally
- The 50-word bulk limit is enforced by the backend
- AI readiness polling and retry live in the planned Library/Detail screens
- Push and PR verification remain pending

