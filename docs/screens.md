# Lexi Mobile — Screens

> UI behavior reference. Exact endpoint payloads and errors live in
> [`api-contract.md`](api-contract.md).

## Navigation

```
Main shell (bottom navigation)
├── Dashboard (default tab)
├── Library → Word Detail
├── Review → Review Session
└── History

Add Words is a pushed route opened from the shell-level Add word FAB.
Review Session opens full-screen without the bottom navigation bar.
```

## 1. Home / Dashboard

**Purpose:** Overview of progress and today's review load.

**Current implementation:** The default tab inside the four-tab `MainShellPage`.
Loads today's review counts, progress stats, the learning mix, and up to five weakest
words from `GET /api/dashboard`. The empty-library state links to Add Words.

**Endpoints:** `GET /api/dashboard`

**Content:**
- Today: due, new, need attention, becoming strong
- Stats: total words, status counts, reviews today, 7-day accuracy, streak
- Up to 5 weakest words

**Actions:** Start review when words are due, add words from the FAB or empty state,
open a weakest word in Word Detail, refresh, and switch tabs.

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
- Source URL is accepted as free text and is not validated locally.
- AI polling happens in Library/Detail, not here.

## 3. Vocabulary Library

**Purpose:** Browse, search, filter, and sort saved words.

**Endpoints:** `GET /api/vocabulary`

**Current implementation:** The Library tab inside `MainShellPage`. Phase 3 library
with 20-item pages, submit-only search, status chips, backend-supported sorting,
word cards, and load-more pagination.

**Content:**
- Search field
- Status filter: New, Learning, Familiar, Strong, Mastered
- Sort: date added, word (current backend support)
- Future backend support needed for score and next-review sorting
- Word rows with status and AI-ready/pending indicator
- Pagination

**Actions:** Search on submit, filter, sort, paginate, open Word Detail; use the shell
Add word FAB to add more words.

**States:** Loading; empty with add-word CTA; no matches with clear filters; initial
error with retry; inline load-more error; populated.

## 4. Word Detail

**Purpose:** View a word's full AI content and learning state.

**Current implementation:** Phase 3 detail with AI content, learning state, source,
recent reviews, bounded pending-AI polling, regenerate, and soft delete.

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

**Actions:** Check again, regenerate AI, delete word with confirmation, return to library.

**States:** Loading; not found; AI pending; polling exhausted; action error; deleted.

**Rules:** Delete is a soft delete. Regenerate uses the 60-second AI timeout. Pending
AI polls at 3s, 6s, 12s, 20s, and 30s, then stops. Source URLs are selectable text,
not external links.

## 5. Review

**Purpose:** Start and complete today's review queue.

**Current implementation:** The Review tab lists today's counts and queue, including
AI-pending items. Tapping Start review opens the full-screen Review Session. The
session skips AI-pending words, shows one exercise per word, submits answers to the
server, shows feedback, and finishes with a summary. Completing or closing a session
refreshes the Review tab. The API returns up to three exercises per word; this first
version uses the first exercise for each queue word.

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

**Current implementation:** The History tab loads the newest-first paginated review
list (20 per page), shows result badges and timing/hint details, supports Load more,
refreshes, and opens the reviewed word in Word Detail. The data layer and query support
an optional `wordId` filter; no filter entry point is exposed yet.

**Endpoints:** `GET /api/review/history`

**Content:**
- Word, exercise type, result, response time, hint usage, timestamp
- Optional word filter
- Pagination

**Actions:** Refresh, load more, and open Word Detail. Word filtering is supported by the data layer but not yet exposed in the UI.

**States:** Loading; empty; error with retry; populated.

## Shared UI Rules

- Use theme values only; no hardcoded colors.
- Every async screen handles loading, empty, and error states.
- Errors expose retry where retrying is safe.
- Widgets dispatch actions; business logic stays in blocs/use cases.
