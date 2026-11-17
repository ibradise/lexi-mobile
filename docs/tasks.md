# Lexi Mobile — Implementation Tasks

> Current phase only. See `docs/architecture.md` for the approved architecture,
> `docs/api-contract.md` for endpoint payloads, and `docs/screens.md` for screen
> behavior.

---

## Phase 2: Add Words

**Scope:** Single and bulk word entry. Keep the home route as a minimal landing
screen with an Add Words CTA. Show AI ready/pending results; do not poll here.
No new dependencies.

### Domain

- [ ] Add `VocabularyWord` entity with `id`, `word`, and `aiReady`
- [ ] Add `AddedWord` and `BulkAddResult` entities
- [ ] Add `AddWordParams` with word, context, source title, and source URL
- [ ] Add `VocabularyRepository` interface with `addWord` and `addWords`
- [ ] Add `AddWord` use case that trims input and delegates to the repository
- [ ] Add `AddWords` use case that trims pasted input and delegates to the repository

### Data

- [ ] Add `VocabularyWordModel` with parsing for ready and pending AI responses
- [ ] Add `AddedWordModel` and `BulkAddResultModel`
- [ ] Add `VocabularyRemoteDataSource` for `POST /vocabulary` single and bulk requests
- [ ] Send only non-null optional fields in the single-word body
- [ ] Use the 60-second AI timeout for single add and the standard timeout for bulk
- [ ] Add `VocabularyRepositoryImpl` with model-to-entity mapping
- [ ] Translate data-layer exceptions to `AppFailure` through the existing mapper
- [ ] Register the data source, repository, use cases, and bloc factory in GetIt

### Presentation

- [ ] Replace the placeholder page with a minimal `HomePage` and an Add Words CTA
- [ ] Add `AppRoutes.addWord` and register it in `AppRouter`
- [ ] Add `AddWordBloc` events: single submit, bulk submit, reset
- [ ] Add states: idle, submitting, single success, bulk success, failure
- [ ] Add the Add Words screen with a single/bulk mode switch
- [ ] Single form: word, context, source title, source URL
- [ ] Bulk form: multiline paste field
- [ ] Validate required word and 100-character limit locally
- [ ] Validate non-empty bulk input locally
- [ ] Show loading and disable submit while a request is in flight
- [ ] Show single success with AI ready or pending status
- [ ] Show bulk summary with added, duplicate, and invalid counts
- [ ] Show duplicate, validation, and network errors with retry
- [ ] Add an "Add another" action that resets the form and bloc
- [ ] Use theme values only; no hardcoded colors

### Tests

- [ ] Test single-word model mapping for ready and pending responses
- [ ] Test bulk result model mapping
- [ ] Test data source paths, request bodies, omitted nulls, and timeouts
- [ ] Test repository entity mapping and failure translation
- [ ] Test use case trimming and repository delegation
- [ ] Test bloc single success, pending, duplicate, bulk success, and failure
- [ ] Test form validation, mode switching, success, and error rendering
- [ ] Update the app shell test for the new home CTA

### Documentation

- [ ] Append the Phase 2 entry to `docs/IMPLEMENTATION.md`
- [ ] Correct the stale Phase 1 note that says no git repository was initialized
- [ ] Update `docs/architecture.md` if the code structure changed
- [ ] Update `docs/screens.md` if implemented behavior differs
- [ ] Update `docs/api-contract.md` if the backend contract changed

### Verification

- [ ] `dart format --output=none --set-exit-if-changed lib test`
- [ ] `flutter analyze` passes with no issues
- [ ] `flutter test` passes
- [ ] `flutter build apk --debug` succeeds
- [ ] Push `feat/add-word-flow`, open a PR, and pass the `Analyze, test, and build` check

---

Do not start Phase 3 or clear this file until the user approves the completed
Phase 2 work.
