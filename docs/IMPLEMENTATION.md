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


## 2026-11-20 — Phase 3: Vocabulary Library + Word Detail

- [x] Added `LearningStatus`, `LearningState`, `WordSummary`, `WordDetail`, `AiContent`, `WordMeaning`, `WordExample`, and `ReviewEntry` domain types
- [x] Added `VocabularyQuery` with search, status, backend-supported sorting, ordering, and pagination
- [x] Extended `VocabularyRepository` and added `GetWords`, `GetWordDetail`, `DeleteWord`, and `RegenerateWordAi`
- [x] Added list/detail models for summaries, learning state, AI content, reviews, and page metadata
- [x] Added `GET /api/vocabulary` with search, status, sort, order, page, and limit
- [x] Added `GET /api/vocabulary/:id`, `DELETE /api/vocabulary/:id`, and `POST /api/vocabulary/:id/regenerate-ai`
- [x] Used the 15-second timeout for list/detail/delete and the 60-second AI timeout for regenerate
- [x] Extended `VocabularyRepositoryImpl` with model-to-entity mapping and `AppFailure` translation
- [x] Added `LibraryBloc` with load, search submit/clear, status filter, sort, clear filters, and load-more events
- [x] Added `WordDetailBloc` with load, bounded polling, regenerate, and delete events
- [x] Added `LibraryPage` with search, status chips, sort menu, word cards, pagination, empty, no-match, and error states
- [x] Added `WordDetailPage` with AI content, learning state, source details, reviews, pending-AI actions, regenerate confirmation, and delete confirmation
- [x] Added `/library` and the typed `/word-detail` route using the word id as the route argument
- [x] Added a bottom-navigation `MainShellPage` with Dashboard and Library tabs and a shell-level Add word FAB
- [x] Added shell-scoped `LibraryBloc` and route-scoped `WordDetailBloc` providers through GetIt factories
- [x] Refreshed the library after Add Words and after a successful delete
- [x] Added Phase 3 model, data source, repository, use case, bloc, and widget tests

## Screens Implemented (mobile)

- Dashboard/Home — default bottom-navigation tab with a dashboard placeholder and empty-activity guidance
- Vocabulary Library — bottom-navigation tab with search, status filters, sort, paginated word cards, empty/no-match/error states
- Word Detail — AI content, learning state, source, reviews, pending-AI polling, regenerate, and soft delete

## API Integration

- `GET /api/vocabulary` with `search`, `status`, `sort`, `order`, `page`, and `limit`; 15-second timeout
- `GET /api/vocabulary/:id`; 15-second timeout
- `DELETE /api/vocabulary/:id`; 15-second timeout; expects `{ id, isArchived: true }`
- `POST /api/vocabulary/:id/regenerate-ai`; 60-second AI timeout
- List pagination `meta` maps to `PaginatedResult<WordSummary>`; missing metadata is a parse failure
- Pending AI detail polls at 3s, 6s, 12s, 20s, and 30s, then stops and offers manual retry/regenerate

## Tests

- Models: learning state, ready/pending summaries, AI content, reviews, and missing AI content
- Remote data source: query filters, omitted empty filters, encoded ids, delete confirmation, regenerate, and missing pagination meta
- Repository: page mapping, detail/regenerate mapping, delete delegation, and not-found translation
- Use cases: search trimming, page/limit bounds, blank search clearing, and trimmed ids
- `LibraryBloc`: load, empty page, search/filter/sort, pagination, and load failure
- `WordDetailBloc`: ready, pending polling, exhausted polling, regenerate, delete, delete 404, not-found, action failure, and disposed-poll cancellation
- Widgets: bottom navigation, tab switching, Add FAB navigation, library empty/populated/search states, row navigation, detail content, pending AI, and delete confirmation
- Result: 93 tests pass

## Verification

- `dart format --output=none --set-exit-if-changed lib test` — no changes
- `flutter analyze` — no issues
- `flutter test` — 93 tests pass
- `flutter build apk --debug` — succeeded
- Build output: `build/app/outputs/flutter-apk/app-debug.apk`
- No Android device or emulator was connected for a manual launch

## Notes

- No new dependencies were added
- Dashboard is the default tab; Library uses the same bottom-navigation shell
- The library uses page size 20 and explicit Load more pagination
- Sorting is limited to newest, oldest, A–Z, and Z–A because the backend supports only `dateAdded` and `word`
- Source URLs are selectable text; `url_launcher` is intentionally not added
- Pending AI polling stops after the bounded schedule and exposes "Check again" and "Regenerate AI"
- Phase 3 changes are committed on the feature branch and not yet pushed


## 2026-11-20 — Phase 4: Review Flow

- [x] Added review domain entities: queue, exercise, submission, score breakdown, and submission result
- [x] Added `ReviewRepository` with today's queue, exercises, and submit operations
- [x] Added `GetTodayReview`, `GetReviewExercises`, and `SubmitReview` use cases with id/answer validation
- [x] Added review queue, exercise, and submission-result models plus `ReviewRemoteDataSource`
- [x] Added `GET /api/review/today`, `GET /api/vocabulary/:id/exercises`, and `POST /api/review/:wordId/submit`
- [x] Mapped review failures, including the explicit `AI_NOT_READY` (`409`) path
- [x] Added `ReviewQueueBloc` for queue loading, retry, and start-session navigation state
- [x] Added `ReviewSessionBloc` for one-exercise-per-word sessions, AI-pending skips, submit/skip, retry, counts, and completion
- [x] Added `ReviewPage` with due/new/attention counts, pending-AI notice, queue preview, empty/error/retry states, and Start review
- [x] Added full-screen `ReviewSessionPage` with options, submit/skip, feedback, progress, exit confirmation, and completion summary
- [x] Expanded `MainShellPage` to Dashboard, Library, Review, and History tabs with lazy review loading and the Add word FAB
- [x] Added `/review`, `/history`, and `/review-session` routes; Review Session is pushed outside the shell
- [x] Added Review History placeholder inside the shell until its data slice
- [x] Added model, data source, repository, use case, bloc, and widget tests
- [x] Updated four-tab shell widget tests and the Review empty state

## Screens Implemented (mobile)

- Dashboard/Home — default tab with dashboard placeholder; real dashboard data is next
- Vocabulary Library — search, status filters, sort, paginated word cards, and states
- Word Detail — AI content, learning state, source, reviews, polling, regenerate, and delete
- Review — today's queue with counts, start action, and AI-pending notice
- Review Session — full-screen one-question flow with server feedback and completion summary
- History — placeholder tab until the review history slice

## API Integration

- `GET /api/review/today`; 15-second timeout; queue is capped at 30 and omits AI content
- `GET /api/vocabulary/:id/exercises`; 15-second timeout; requires AI-ready words
- `POST /api/review/:wordId/submit`; 15-second timeout; server determines the result
- `AI_NOT_READY` is surfaced as a skipped word with a pending count, not a hard session failure

## Tests

- Models: queue counts/items, exercises, submission results, score breakdown, and malformed payloads
- Remote data source: queue, encoded exercise ids, submit body, omitted options, and `AI_NOT_READY`
- Repository: queue/exercise/result mapping, submit delegation, and failure translation
- Use cases: id/answer validation and delegation
- `ReviewQueueBloc`: load, empty, failure, retry, start action, and disposed safety
- `ReviewSessionBloc`: start, AI skips, answer, skip, retry after failure, completion, and empty queue
- Widgets: Review tab states, start/session navigation, answer feedback, skip, completion, and History placeholder
- Result: 129 tests pass

## Verification

- `dart format --output=none --set-exit-if-changed lib test` — no changes
- `flutter analyze` — no issues
- `flutter test --concurrency=1` — 129 tests pass
- `flutter build apk --debug` — succeeded
- Build output: `build/app/outputs/flutter-apk/app-debug.apk`
- Review and dashboard flows are not yet verified against a live local backend in this session

## Notes

- No new dependencies were added
- The four bottom tabs are Dashboard, Library, Review, and History
- Review uses one exercise per word in this first version; the API returns up to three
- AI-pending queue items are shown on the Review tab and skipped by the session
- Submissions use a generated `submissionId` for idempotency and send server-authoritative answers
- Review History is the remaining MVP screen
- Phase 4 changes are not committed yet

## 2026-11-20 — Phase 4: Dashboard

- [x] Added `DashboardData`, today's review counts, weakest word, and stats entities
- [x] Added `DashboardRepository` and the `GetDashboard` use case
- [x] Added dashboard models for today's counts, weakest words, and progress stats
- [x] Added `GET /api/dashboard` with the standard 15-second timeout
- [x] Added `DashboardRepositoryImpl` mapping and `AppFailure` translation
- [x] Added `DashboardBloc` with load, refresh, retry, and stale-request protection
- [x] Replaced the dashboard placeholder with today's review card, Start review, progress stat cards, learning mix, and weakest words
- [x] Added an empty-library dashboard state with an Add words CTA
- [x] Added dashboard retry and refresh actions
- [x] Wired the dashboard into the shell as the default tab with lazy loading
- [x] Refreshed the dashboard after adding words, completing a review, and returning from a weakest word
- [x] Opened weakest words in Word Detail and refreshed the dashboard after deletion
- [x] Added dashboard model, data source, repository, use case, bloc, and widget tests
- [x] Updated shell widget mocks for `GET /api/dashboard`

## Screens Implemented (mobile)

- Dashboard/Home — today's review counts, Start review, progress stats, learning mix, and weakest words
- Vocabulary Library — search, status filters, sort, paginated word cards, and states
- Word Detail — AI content, learning state, source, reviews, polling, regenerate, and delete
- Review — today's queue with counts, start action, and AI-pending notice
- Review Session — full-screen one-question flow with server feedback and completion summary
- History — placeholder tab until the review history slice

## API Integration

- `GET /api/dashboard`; 15-second timeout; today's counts, stats, and up to five weakest words
- `GET /api/review/today`; 15-second timeout; queue is capped at 30 and omits AI content
- `GET /api/vocabulary/:id/exercises`; 15-second timeout; requires AI-ready words
- `POST /api/review/:wordId/submit`; 15-second timeout; server determines the result
- `AI_NOT_READY` is surfaced as a skipped word with a pending count, not a hard session failure

## Tests

- Dashboard models: counts, stats, weakest words, empty library, and malformed responses
- Dashboard data source: path, malformed payload, and incomplete data
- Dashboard repository and use case: mapping, delegation, and failure translation
- `DashboardBloc`: load and failure
- Dashboard widgets: populated content, Start review, weakest-word navigation, empty CTA, and retry
- Result: 146 tests pass

## Verification

- `dart format --output=none --set-exit-if-changed lib test` — no changes
- `flutter analyze` — no issues
- `flutter test --concurrency=1` — 146 tests pass
- `flutter build apk --debug` — succeeded
- Build output: `build/app/outputs/flutter-apk/app-debug.apk`
- Dashboard is not yet verified against a live local backend in this session

## Notes

- No new dependencies were added
- Dashboard is loaded when the shell opens on the default tab; it is also refreshed after mutations
- The dashboard uses the server's `new` field for the new-word count
- Start review appears only when at least one word is due
- Weakest words are capped by the backend at five
- Review History is the remaining MVP screen
- Phase 4 changes are not committed yet


## 2026-11-20 — Phase 4: Review History

- [x] Added `ReviewHistoryItem` and `ReviewHistoryQuery` with optional word filter and pagination
- [x] Extended `ReviewRepository` with `getHistory`
- [x] Added the `GetReviewHistory` use case with trimmed word ids and bounded pagination
- [x] Added review history item and page models with the nested `word` relation
- [x] Added `GET /api/review/history` with `wordId`, `page`, and `limit`
- [x] Added `ReviewHistoryBloc` with load, refresh, load more, word filter, failure, and stale-request protection
- [x] Replaced the History placeholder with a newest-first paginated list, result badges, timing/hint details, empty/error states, and Load more
- [x] Loaded History lazily when the tab is selected and refreshed it after review activity
- [x] Opened Word Detail from history rows and refreshed after deletion
- [x] Added history model, data source, repository, use case, bloc, and widget tests
- [x] Added a shell widget test for the empty History tab

## Screens Implemented (mobile)

- Dashboard/Home — today's review counts, Start review, progress stats, learning mix, and weakest words
- Vocabulary Library — search, status filters, sort, paginated word cards, and states
- Word Detail — AI content, learning state, source, reviews, polling, regenerate, and delete
- Review — today's queue with counts, start action, and AI-pending notice
- Review Session — full-screen one-question flow with server feedback and completion summary
- Review History — paginated newest-first activity with result badges and word navigation

## API Integration

- `GET /api/dashboard`; 15-second timeout; today's counts, stats, and up to five weakest words
- `GET /api/review/today`; 15-second timeout; queue is capped at 30 and omits AI content
- `GET /api/vocabulary/:id/exercises`; 15-second timeout; requires AI-ready words
- `POST /api/review/:wordId/submit`; 15-second timeout; server determines the result
- `GET /api/review/history`; 15-second timeout; 20 per page with optional `wordId`
- `AI_NOT_READY` is surfaced as a skipped word with a pending count, not a hard session failure

## Tests

- History models: nested word relation, results, timing, hints, and page mapping
- History data source: optional word filter, page/limit, metadata, and missing-meta failure
- History repository and use case: mapping, failure translation, trimming, and pagination bounds
- `ReviewHistoryBloc`: first page, load more, word filter, and failure
- History widgets: populated list, word navigation, empty state, and retry
- Shell widgets: History tab opens the empty state
- Result: 164 tests pass

## Verification

- `dart format --output=none --set-exit-if-changed lib test` — no changes
- `flutter analyze` — no issues
- `flutter test --concurrency=1` — 164 tests pass
- `flutter build apk --debug` — succeeded
- Build output: `build/app/outputs/flutter-apk/app-debug.apk`
- All four tabs and all MVP screens are implemented; live-backend verification and visual polish remain

## Notes

- No new dependencies were added
- All four bottom tabs are now functional: Dashboard, Library, Review, and History
- Review History loads lazily and is refreshed after add/review/delete activity
- The history data layer supports `wordId` filtering; the first UI version does not expose a filter control
- Review History uses explicit Load more pagination with 20 items per page
- Phase 4 changes are not committed yet
