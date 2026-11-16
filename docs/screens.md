# Lexi Mobile — Screens

> UI behavior reference. Exact endpoint payloads and errors live in
> [`api-contract.md`](api-contract.md).

## Navigation

```
Home / Dashboard
├── Add Words
├── Vocabulary Library → Word Detail
├── Review Session
└── Review History
```

## 1. Home / Dashboard

**Purpose:** Overview of progress and today's review load.

**Endpoints:** `GET /api/dashboard`

**Content:**
- Today: due, new, need attention, becoming strong
- Stats: total words, status counts, reviews today, 7-day accuracy, streak
- Up to 5 weakest words

**Actions:** Start review, add words, open library, open review history.

**States:** Loading; error with retry; empty library with an add-word CTA; populated.

## 2. Add Words

**Purpose:** Add one word or paste a list.

**Endpoints:** `POST /api/vocabulary` — `{ word, ... }` or `{ words: [...] }`

**Content:**
- Single form: word, context, source title, source URL
- Bulk form: multiline paste
- Result summary: added count, duplicates, invalid entries

**Actions:** Switch single/bulk mode, submit, add another.

**States:**
- Idle and submitting
- Single success: AI ready or pending
- Bulk success: words created, AI pending
- Duplicate, validation, and network errors with retry
- Empty/invalid input validation

**Rules:**
- Word is required and limited to 100 characters.
- Bulk input must not be empty; the backend enforces the 50-word limit.
- AI polling happens in Library/Detail, not here.

## 3. Vocabulary Library

**Purpose:** Browse, search, filter, and sort saved words.

**Endpoints:** `GET /api/vocabulary`

**Content:**
- Search field
- Status filter: New, Learning, Familiar, Strong, Mastered
- Sort: date added, word (current backend support)
- Future backend support needed for score and next-review sorting
- Word rows with status and AI-ready/pending indicator
- Pagination

**Actions:** Search, filter, sort, paginate, open Word Detail.

**States:** Loading; empty with add-word CTA; error with retry; populated.

## 4. Word Detail

**Purpose:** View a word's full AI content and learning state.

**Endpoints:**
- `GET /api/vocabulary/:id`
- `DELETE /api/vocabulary/:id`
- `POST /api/vocabulary/:id/regenerate-ai`

**Content:**
- Word, pronunciation, difficulty, part of speech
- Meanings, examples, synonyms, antonyms
- Source context/title/URL
- Learning state and recent review history
- AI pending or ready state

**Actions:** Regenerate AI, delete word with confirmation, return to library.

**States:** Loading; not found; AI pending; error with retry.

**Rules:** Delete is a soft delete. Regenerate uses the 60-second AI timeout.

## 5. Review Session

**Purpose:** Review today's queue one exercise at a time.

**Endpoints:**
- `GET /api/review/today`
- `GET /api/vocabulary/:id/exercises`
- `POST /api/review/:wordId/submit`

**Content:**
- Word and multiple-choice question
- Answer options
- Correct/incorrect feedback and explanation
- Session progress and final summary

**Actions:** Select answer, submit, skip, continue, finish session.

**States:** Loading queue; empty queue; exercise loading; submitting; result feedback; AI-not-ready; error with retry.

**Rules:**
- One exercise at a time.
- Send `exerciseId`, `userAnswer`, timing, hint usage, and an optional idempotent `submissionId`.
- The server determines the result.

## 6. Review History

**Purpose:** Browse past review activity.

**Endpoints:** `GET /api/review/history`

**Content:**
- Word, exercise type, result, response time, hint usage, timestamp
- Optional word filter
- Pagination

**Actions:** Paginate, filter by word, open Word Detail.

**States:** Loading; empty; error with retry; populated.

## Shared UI Rules

- Use theme values only; no hardcoded colors.
- Every async screen handles loading, empty, and error states.
- Errors expose retry where retrying is safe.
- Widgets dispatch actions; business logic stays in blocs/use cases.
