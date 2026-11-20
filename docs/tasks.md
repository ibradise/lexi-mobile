# Lexi Mobile — Implementation Tasks

## Phase 3: Vocabulary Library + Word Detail

> Scope: library list/search/filter/sort/pagination, word detail, AI-readiness
> polling, regenerate AI, and soft delete. Review Session, Review History, and
> Dashboard remain later phases. Vocabulary Library is already in the approved
> MVP scope, so no new proposal is required.

> Backend sorting currently supports only `dateAdded` and `word`. The UI must
> not expose knowledge-score or next-review sorting until the backend supports it.

### Domain

- [x] Add `LearningStatus` enum mapped to `NEW`, `LEARNING`, `FAMILIAR`, `STRONG`, `MASTERED`.
- [x] Add `LearningState` entity with status, knowledge score, interval, repetitions, and review dates.
- [x] Add `WordSummary` entity for list items: id, word, part of speech, pronunciation, difficulty, source fields, date added, AI readiness, and learning state.
- [x] Add `WordDetail` entity with summary fields, AI content, AI model, AI updated date, and recent reviews.
- [x] Add `AiContent`, `WordMeaning`, `WordExample`, and `ReviewEntry` entities.
- [x] Add `VocabularyQuery`, status-filter, sort, and order values.
- [x] Extend `VocabularyRepository` with list, detail, delete, and regenerate-AI operations.
- [x] Add use cases `GetWords`, `GetWordDetail`, `DeleteWord`, and `RegenerateWordAi`.
- [x] Keep `domain/` free of Flutter, `http`, JSON, and data-layer imports.

### Data

- [x] Add list/detail models for `WordSummary`, `WordDetail`, `LearningState`, `AiContent`, and `ReviewEntry`.
- [x] Parse nullable fields safely and default `reviews` to an empty list when absent.
- [x] Add `GET /vocabulary` with `search`, `status`, `sort`, `order`, `page`, and `limit`; omit empty parameters and use the 15-second timeout.
- [x] Add `GET /vocabulary/:id` with a URL-encoded id and the 15-second timeout.
- [x] Add `DELETE /vocabulary/:id` with the 15-second timeout.
- [x] Add `POST /vocabulary/:id/regenerate-ai` with the 60-second AI timeout.
- [x] Map list pagination `meta` into `PaginatedResult<WordSummary>` and treat missing meta as a parse failure.
- [x] Extend `VocabularyRepositoryImpl` with model-to-entity mapping and `AppFailure` translation.
- [x] Register the new use cases and blocs in GetIt without calling GetIt inside blocs.

### Vocabulary Library

- [x] Add `LibraryBloc` with events for initial load, search submit/clear, status filter, sort, refresh, retry, and load more.
- [x] Keep page size at 20 and append results for subsequent pages.
- [x] Add `LibraryPage` with search field, status filter, sort menu, word rows, pagination, and AI-ready/pending indicators.
- [x] Support sort options: newest, oldest, A–Z, and Z–A only.
- [x] Show loading, initial error with retry, inline load-more error, empty-library CTA, and no-match state with clear filters.
- [x] Navigate to Word Detail when a row is tapped.
- [x] Refresh the library after returning from a successful delete.
- [x] Add a bottom-navigation shell with Dashboard and Library tabs plus a shell-level Add word FAB.

### Word Detail

- [x] Add `WordDetailBloc` with load, poll, regenerate, and delete events plus distinct loading, ready, pending, not-found, deleting, and error states.
- [x] Add `WordDetailPage` showing word, pronunciation, part of speech, difficulty, learning status, knowledge score, source details, AI content, and recent reviews.
- [x] Show a pending-AI state with a manual retry and a `Regenerate AI` action.
- [x] Poll pending words with bounded backoff (3s, 6s, 12s, 20s, 30s), stopping when ready, disposed, or exhausted.
- [x] Regenerate AI with confirmation, the 60-second timeout, and a refreshed detail result.
- [x] Delete with confirmation, handle success and `404`, then return to the library with a refresh signal.
- [x] Display source URL as selectable text; do not add `url_launcher` or another dependency.
- [x] Use theme values only and handle empty review history.

### Navigation and DI

- [x] Add `/library` and a typed Word Detail route that receives the word id; `/` and `/library` open the shell on their respective tabs.
- [x] Provide `LibraryBloc` at shell scope and `WordDetailBloc` at route scope.
- [x] Register all new repository methods, use cases, and bloc factories in `injection.dart`.
- [x] Keep Flutter's built-in `Navigator`; no routing package.

### Tests

- [x] Model tests: list ready/pending, detail with and without AI content, learning state, reviews, and missing pagination meta.
- [x] Remote data source tests: query parameters, omitted filters, encoded ids, delete, regenerate, and timeouts.
- [x] Repository tests: mapping, pagination, delete, regenerate, and failure translation.
- [x] Use case tests: delegation and query validation.
- [x] `LibraryBloc` tests: load, filter, search submit, sort, pagination, empty, and error retry.
- [x] `WordDetailBloc` tests: ready, pending polling, exhausted polling, regenerate, delete, not-found, and disposed-poll cancellation.
- [x] Widget tests: bottom navigation, tab switching, Add FAB navigation, library states, row navigation, detail content, pending state, and delete confirmation.
- [x] Remove or update tests that assume the Phase 2-only home screen.

### Documentation and verification

- [x] Update `docs/IMPLEMENTATION.md` with Phase 3.
- [x] Update `docs/architecture.md` with new files, routes, and current screens.
- [x] Update `docs/screens.md` only if implemented behavior differs from the spec.
- [x] Update `docs/api-contract.md` only if the backend contract changes.
- [x] Run `dart format --output=none --set-exit-if-changed lib test`.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Run `flutter build apk --debug`.
- [x] Check off completed tasks while building.
- [x] **STOP and ask for approval before clearing this file.**

---

Phase 3 implementation and verification are complete and approved. Phase 4 begins
below; Phase 3 stays here until the next approved cleanup.


## Phase 4: Review, Dashboard, and History

> Scope: complete the four-tab MVP shell. All MVP screens are implemented; polish
> and live-backend verification remain. No new proposal is required because these screens are in
> the approved MVP scope.

### Review

- [x] Add `ReviewQueue`, `ReviewExercise`, `ReviewSubmission`, `ScoreBreakdown`, and `ReviewSubmissionResult` entities.
- [x] Add `ReviewRepository` plus `GetTodayReview`, `GetReviewExercises`, and `SubmitReview` use cases.
- [x] Add review queue, exercise, and submission-result models.
- [x] Add `ReviewRemoteDataSource` for today's queue, exercises, and submit endpoints.
- [x] Add `ReviewRepositoryImpl` with model mapping and `AppFailure` translation.
- [x] Handle exercise `AI_NOT_READY` (`409`) as a skipped word, not a hard failure.
- [x] Add `ReviewQueueBloc` with load, retry, and start-session events.
- [x] Add `ReviewSessionBloc` with start, answer, skip, retry, progress, counts, and completion.
- [x] Add `ReviewPage` with due/new/attention counts, pending-AI notice, queue preview, start action, and states.
- [x] Add full-screen `ReviewSessionPage` with multiple-choice options, feedback, skip, exit confirmation, and completion summary.
- [x] Use one exercise per word for the first version.
- [x] Refresh the Review tab after a session completes or is closed.

### Four-tab shell

- [x] Expand `MainShellPage` to Dashboard, Library, Review, and History.
- [x] Load the review queue lazily when the Review tab is first selected.
- [x] Keep the shell-level Add word FAB on shell tabs.
- [x] Keep Review Session outside the shell with no bottom navigation.
- [x] Add `/review`, `/history`, and `/review-session` routes.
- [x] Add a Review History placeholder UI until the history slice.
- [x] Register review data sources, repository, use cases, and bloc factories in GetIt.

### Dashboard

- [x] Add dashboard entities and models for counts, stats, and weakest words.
- [x] Add `DashboardRemoteDataSource`, repository method, use case, and `DashboardBloc`.
- [x] Replace the dashboard placeholder with today's load, stats, and weakest words.
- [x] Add a Start review action that opens `/review-session`.
- [x] Add loading, error with retry, empty-library CTA, and populated states.
- [x] Add dashboard model, data source, repository, use case, bloc, and widget tests.
- [x] Open a weakest word in Word Detail and refresh after deletion.
- [x] Refresh the dashboard after adding words or completing a review.

### Review History

- [x] Add review history entities, models, filtering, and pagination.
- [x] Add the `GET /api/review/history` data source method, repository method, and use case.
- [x] Replace the History placeholder with a paginated list and refresh action.
- [x] Support an optional `wordId` query in the data layer and bloc; filter UI remains future polish.
- [x] Open Word Detail from history rows.
- [x] Add history model, data source, repository, use case, bloc, and widget tests.
- [x] Load the history tab lazily and refresh it after review activity.

### Tests and verification

- [x] Run `dart format --output=none --set-exit-if-changed lib test`.
- [x] Run `flutter analyze`.
- [x] Run `flutter test --concurrency=1` — 164 tests pass.
- [x] Run `flutter build apk --debug`.
- [x] Verify four-tab navigation, review queue, session submission, and History placeholder in widget tests.
- [x] Verify the Dashboard slice with unit and widget tests.
- [x] Verify the Review History slice with unit and widget tests.
- [ ] **STOP and ask for approval before clearing this file.**
