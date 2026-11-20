# Lexi Mobile — Backend API Contract

> Mobile-facing contract for the Lexi backend.
>
> Verified against `lexi-backend` commit `6350763` on 2026-11-14. The backend
> source code remains the source of truth. Update this file in the same PR as
> any backend contract change.

---

## 1. Connection

| Item | Value |
|------|-------|
| Production base URL | `https://lexi-backend-z0zy.onrender.com/api` |
| Override | `--dart-define=API_BASE_URL=...` |
| Android emulator | `http://10.0.2.2:3001/api` |
| Local backend | `http://localhost:3001/api` |
| Auth | None in the MVP |
| Request headers | `Accept: application/json`; `Content-Type: application/json` when a body is sent |
| Standard timeout | 15 seconds |
| AI-dependent timeout | 60 seconds |

Use the standard timeout for normal reads and writes. Use the AI timeout for
`POST /vocabulary` with a single word and
`POST /vocabulary/:id/regenerate-ai`.

The backend may cold-start on Render. The app does not send a startup warm-up
request.

The operational health endpoint is `GET /health` at the host root, not under
`/api`. The mobile app does not use it.

---

## 2. Response Envelope

Every API response uses this envelope.

Success:

```json
{
  "success": true,
  "data": {},
  "error": null,
  "meta": null
}
```

Error:

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Word is required",
    "details": []
  },
  "meta": null
}
```

- `details` is always present. It is normally an empty array, but can be an
  object; `DUPLICATE_WORD` uses `{ "id": "<existing word id>" }`.
- Paginated list responses put the array in `data` and pagination in `meta`.
- Dates are ISO 8601 strings.
- IDs are cuid strings.
- Clients must ignore unknown fields added to response objects in the future.
- Endpoint examples abbreviate nested AI and review content for readability; field
  names, types, and nullability are exact.

### Pagination metadata

```json
{
  "page": 1,
  "limit": 20,
  "total": 42,
  "totalPages": 3
}
```

`totalPages` is `0` when `total` is `0`.

---

## 3. Feature → Endpoint Map

| Feature | Endpoint(s) | Mobile status |
|---------|-------------|---------------|
| Add one word | `POST /api/vocabulary` with `{ word, ... }` | Phase 2 |
| Bulk add words | `POST /api/vocabulary` with `{ words: [...] }` | Phase 2 |
| Library list / search / filter | `GET /api/vocabulary` | Phase 3 |
| Word detail | `GET /api/vocabulary/:id` | Phase 3 |
| Review exercises | `GET /api/vocabulary/:id/exercises` | Planned |
| Delete word | `DELETE /api/vocabulary/:id` | Phase 3 |
| Regenerate AI content | `POST /api/vocabulary/:id/regenerate-ai` | Phase 3 |
| Today's review queue | `GET /api/review/today` | Planned |
| Submit a review answer | `POST /api/review/:wordId/submit` | Planned |
| Review history | `GET /api/review/history` | Planned |
| Dashboard | `GET /api/dashboard` | Planned |
| Health check | `GET /health` | Not used by the app |

---

## 4. Shared Types

### 4.1 `VocabularyWord`

Returned by single-word add, word detail, and regenerate AI. The list endpoint
returns the same scalar fields but omits `aiData` and adds `aiReady`.

```json
{
  "id": "clx0abc123",
  "word": "lexicon",
  "partOfSpeech": "noun",
  "pronunciation": "/ˈleksɪkɒn/",
  "difficulty": 3,
  "sourceContext": "A sentence where the word was found.",
  "sourceUrl": "https://example.com/article",
  "sourceTitle": "Example article",
  "dateAdded": "2026-11-14T09:15:00.000Z",
  "isArchived": false,
  "aiData": {},
  "aiModel": "gemini-3.5-flash",
  "aiUpdatedAt": "2026-11-14T09:15:08.000Z",
  "learningState": {}
}
```

| Field | Type | Notes |
|-------|------|-------|
| `id` | string | cuid |
| `word` | string | Lowercased and trimmed by the server |
| `partOfSpeech` | string \| null | Optional on single add |
| `pronunciation` | string \| null | Set from AI content; null while pending |
| `difficulty` | number | Defaults to `3`; set from AI content when ready |
| `sourceContext` | string \| null | Optional on single add |
| `sourceUrl` | string \| null | Optional on single add |
| `sourceTitle` | string \| null | Optional on single add |
| `dateAdded` | ISO date string | |
| `isArchived` | boolean | Soft-delete flag |
| `aiData` | `AIData` \| null | Omitted from list responses; null while pending |
| `aiModel` | string \| null | `null` while AI content is pending |
| `aiUpdatedAt` | ISO date string \| null | |
| `learningState` | `LearningState` \| null | Present on add/list/detail |
| `reviews` | `ReviewHistory[]` | Detail and regenerate only; latest 20, newest first |

`aiReady` is a computed list-field: `aiModel !== null`.

### 4.2 `LearningState`

```json
{
  "id": "clx0state123",
  "wordId": "clx0abc123",
  "status": "NEW",
  "knowledgeScore": 0,
  "easeFactor": 2.5,
  "intervalDays": 0,
  "repetitions": 0,
  "nextReviewAt": null,
  "lastReviewedAt": null,
  "createdAt": "2026-11-14T09:15:00.000Z",
  "updatedAt": "2026-11-14T09:15:00.000Z"
}
```

`status` is one of `NEW`, `LEARNING`, `FAMILIAR`, `STRONG`, `MASTERED`.

### 4.3 `ReviewHistory`

```json
{
  "id": "clx0review123",
  "submissionId": "device-submission-123",
  "wordId": "clx0abc123",
  "exerciseType": "MULTIPLE_CHOICE",
  "result": "CORRECT",
  "responseTimeMs": 2300,
  "userAnswer": "a word used in tests",
  "correctAnswer": "a word used in tests",
  "hintUsed": false,
  "createdAt": "2026-11-14T09:20:00.000Z"
}
```

The review-history endpoint adds a `word` relation:

```json
{
  "word": {
    "word": "lexicon"
  }
}
```

`result` is one of `CORRECT`, `INCORRECT`, `PARTIAL`, `SKIPPED`. The current
submit endpoint produces `CORRECT`, `INCORRECT`, or `SKIPPED`; it does not
produce `PARTIAL`.

`exerciseType` is one of `DEFINITION_RECALL`, `MULTIPLE_CHOICE`,
`CONTEXT_COMPLETION`, `MEANING_FROM_CONTEXT`, `WORD_SELECTION`,
`SENTENCE_CREATION`, `SIMILAR_WORD_DISTINCTION`. Current exercises are always
`MULTIPLE_CHOICE`.

### 4.4 `AIData`

```json
{
  "meanings": [
    {
      "meaning": "the vocabulary of a language or field",
      "isPrimary": true
    }
  ],
  "examples": [
    {
      "sentence": "The linguist studied the lexicon of the region.",
      "context": "academic"
    }
  ],
  "exercises": [
    {
      "question": "What does 'lexicon' mean?",
      "options": [
        "the vocabulary of a language",
        "a type of flower",
        "a musical instrument",
        "a legal document"
      ],
      "correctAnswer": "the vocabulary of a language",
      "explanation": "A lexicon is the vocabulary of a language or field."
    }
  ],
  "synonyms": ["vocabulary"],
  "antonyms": [],
  "pronunciation": "/ˈleksɪkɒn/",
  "difficulty": 3
}
```

- `examples` are learning content and are not scored.
- `exercises` feed the review flow.
- AI content is generated server-side and stored on the word row.

### 4.5 `BulkAddResult`

```json
{
  "added": [
    {
      "id": "clx0abc123",
      "word": "lexicon",
      "status": "PENDING"
    }
  ],
  "duplicates": ["existingword"],
  "invalid": ["a-very-long-token"]
}
```

`added[].status` is the literal `"PENDING"` in this response. It is not the
`LearningState.status` value. The created words have a `LearningState` with
status `NEW`.

### 4.6 `ScoreBreakdown`

```json
{
  "accuracy": 1,
  "interval": 0.1,
  "responseTime": 0.8,
  "hint": 1,
  "repetition": 0.125
}
```

All components are clamped to `0–1`. Weights: accuracy `0.45`, interval `0.20`,
response time `0.15`, hint `0.10`, repetition `0.10`.

---

## 5. Vocabulary Endpoints

### 5.1 Add a single word

```http
POST /api/vocabulary
Content-Type: application/json
```

Request:

```json
{
  "word": "lexicon",
  "partOfSpeech": "noun",
  "sourceContext": "The linguist studied the lexicon of the region.",
  "sourceUrl": "https://example.com/article",
  "sourceTitle": "Example article"
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `word` | Yes | String; trimmed; 1–100 characters; stored lowercased |
| `partOfSpeech` | No | String |
| `sourceContext` | No | String |
| `sourceUrl` | No | String |
| `sourceTitle` | No | String |

The server waits up to 8 seconds for AI generation.

Success `201` when AI is ready:

```json
{
  "success": true,
  "data": {
    "id": "clx0abc123",
    "word": "lexicon",
    "partOfSpeech": "noun",
    "pronunciation": "/ˈleksɪkɒn/",
    "difficulty": 3,
    "sourceContext": "The linguist studied the lexicon of the region.",
    "sourceUrl": "https://example.com/article",
    "sourceTitle": "Example article",
    "dateAdded": "2026-11-14T09:15:00.000Z",
    "isArchived": false,
    "aiData": {
      "meanings": [],
      "examples": [],
      "exercises": [],
      "synonyms": [],
      "antonyms": [],
      "pronunciation": "/ˈleksɪkɒn/",
      "difficulty": 3
    },
    "aiModel": "gemini-3.5-flash",
    "aiUpdatedAt": "2026-11-14T09:15:08.000Z",
    "learningState": {
      "id": "clx0state123",
      "wordId": "clx0abc123",
      "status": "NEW",
      "knowledgeScore": 0,
      "easeFactor": 2.5,
      "intervalDays": 0,
      "repetitions": 0,
      "nextReviewAt": null,
      "lastReviewedAt": null,
      "createdAt": "2026-11-14T09:15:00.000Z",
      "updatedAt": "2026-11-14T09:15:00.000Z"
    }
  },
  "error": null,
  "meta": null
}
```

Success `201` while AI is still pending: the same shape with `aiData`, `aiModel`,
and `aiUpdatedAt` set to `null`, and `pronunciation` set to `null`.

Errors:

| Status | Code | Cause |
|--------|------|-------|
| `400` | `VALIDATION_ERROR` | Missing/empty/non-string `word`, or more than 100 characters |
| `409` | `DUPLICATE_WORD` | Word already exists, including archived words; `details: { "id": "..." }` |
| `500` | `INTERNAL_ERROR` | Unexpected server failure |

Notes:

- The client should use the 60-second AI timeout.
- A pending response is not an error. The word is created and AI generation
  continues server-side.
- A duplicate response includes the existing word id, which can be used later to
  navigate to its detail.

### 5.2 Bulk add words

```http
POST /api/vocabulary
Content-Type: application/json
```

Request:

```json
{
  "words": [
    "lexicon, syntax",
    "semantics"
  ]
}
```

or:

```json
{
  "words": ["lexicon syntax semantics"]
}
```

The server splits every string on commas and whitespace, lowercases and trims
tokens, removes in-batch repeats, and compares against existing words.

Validation:

- `words` must be a non-empty array.
- The raw `words` array is limited to 50 entries.
- The normalized token set is limited to 50 words.
- Non-string entries and tokens longer than 100 characters go to `invalid`;
  they do not fail the whole request.

Success `202`:

```json
{
  "success": true,
  "data": {
    "added": [
      {
        "id": "clx0abc123",
        "word": "lexicon",
        "status": "PENDING"
      },
      {
        "id": "clx0def456",
        "word": "syntax",
        "status": "PENDING"
      }
    ],
    "duplicates": ["semantics"],
    "invalid": []
  },
  "error": null,
  "meta": null
}
```

Errors:

| Status | Code | Cause |
|--------|------|-------|
| `400` | `VALIDATION_ERROR` | Empty array; more than 50 raw entries; more than 50 normalized words |
| `500` | `INTERNAL_ERROR` | Unexpected server failure |

Notes:

- Bulk add returns immediately. AI generation runs in the background.
- The app can close after the `202`; words are already created.
- To observe AI readiness, use `GET /api/vocabulary` (`aiReady`) or
  `GET /api/vocabulary/:id` (`aiData`, `aiModel`).
- Archived words count as duplicates.

### 5.3 List words

```http
GET /api/vocabulary
```

Query parameters:

| Parameter | Type | Default | Rules |
|-----------|------|---------|-------|
| `search` | string | none | Case-insensitive contains match on `word` |
| `status` | enum | none | `NEW`, `LEARNING`, `FAMILIAR`, `STRONG`, `MASTERED` |
| `sort` | string | `dateAdded` | Only `dateAdded` and `word` are honored |
| `order` | enum | `desc` | `asc` or `desc` |
| `page` | integer | `1` | 1–1,000,000 |
| `limit` | integer | `20` | 1–100 |

An unrecognized `sort` value silently falls back to `dateAdded`. Invalid
`status`, `order`, `page`, or `limit` returns `400 VALIDATION_ERROR`.

Success `200`:

```json
{
  "success": true,
  "data": [
    {
      "id": "clx0abc123",
      "word": "lexicon",
      "partOfSpeech": "noun",
      "pronunciation": "/ˈleksɪkɒn/",
      "difficulty": 3,
      "sourceContext": "The linguist studied the lexicon of the region.",
      "sourceUrl": "https://example.com/article",
      "sourceTitle": "Example article",
      "dateAdded": "2026-11-14T09:15:00.000Z",
      "isArchived": false,
      "aiModel": "gemini-3.5-flash",
      "aiUpdatedAt": "2026-11-14T09:15:08.000Z",
      "learningState": {
        "id": "clx0state123",
        "wordId": "clx0abc123",
        "status": "NEW",
        "knowledgeScore": 0,
        "easeFactor": 2.5,
        "intervalDays": 0,
        "repetitions": 0,
        "nextReviewAt": null,
        "lastReviewedAt": null,
        "createdAt": "2026-11-14T09:15:00.000Z",
        "updatedAt": "2026-11-14T09:15:00.000Z"
      },
      "aiReady": true
    }
  ],
  "error": null,
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "totalPages": 1
  }
}
```

Notes:

- List items never include `aiData`.
- List items always include `aiReady`.
- Archived words are excluded.

### 5.4 Get word detail

```http
GET /api/vocabulary/:id
```

Success `200`: a `VocabularyWord` with `aiData`, `learningState`, and the latest
20 `reviews` (newest first).

```json
{
  "success": true,
  "data": {
    "id": "clx0abc123",
    "word": "lexicon",
    "partOfSpeech": "noun",
    "pronunciation": "/ˈleksɪkɒn/",
    "difficulty": 3,
    "sourceContext": "The linguist studied the lexicon of the region.",
    "sourceUrl": "https://example.com/article",
    "sourceTitle": "Example article",
    "dateAdded": "2026-11-14T09:15:00.000Z",
    "isArchived": false,
    "aiData": {},
    "aiModel": "gemini-3.5-flash",
    "aiUpdatedAt": "2026-11-14T09:15:08.000Z",
    "learningState": {},
    "reviews": []
  },
  "error": null,
  "meta": null
}
```

Errors:

| Status | Code | Cause |
|--------|------|-------|
| `404` | `NOT_FOUND` | Missing or archived word |

`aiData` and `aiModel` are `null` while AI content is pending.

### 5.5 Get review exercises

```http
GET /api/vocabulary/:id/exercises
```

Success `200`:

```json
{
  "success": true,
  "data": {
    "wordId": "clx0abc123",
    "word": "lexicon",
    "exercises": [
      {
        "id": "clx0abc123-ex-0",
        "type": "MULTIPLE_CHOICE",
        "question": "What does 'lexicon' mean?",
        "options": [
          "the vocabulary of a language",
          "a type of flower",
          "a musical instrument",
          "a legal document"
        ],
        "correctAnswer": "the vocabulary of a language",
        "explanation": "A lexicon is the vocabulary of a language or field."
      }
    ]
  },
  "error": null,
  "meta": null
}
```

Notes:

- Returns 1–3 randomly selected exercises. Normal AI content has multiple
  exercises; the server returns at most 3.
- Exercise IDs are stable for the word's current `aiData`:
  `<wordId>-ex-<aiDataIndex>`.
- `correctAnswer` is included so the client can give instant feedback.
- Submit `exerciseId`, not the question or options, to the review endpoint.

Errors:

| Status | Code | Cause |
|--------|------|-------|
| `404` | `NOT_FOUND` | Missing or archived word |
| `409` | `AI_NOT_READY` | `aiData` is still null |

### 5.6 Delete a word

```http
DELETE /api/vocabulary/:id
```

Success `200`:

```json
{
  "success": true,
  "data": {
    "id": "clx0abc123",
    "isArchived": true
  },
  "error": null,
  "meta": null
}
```

Notes:

- This is a soft delete (`isArchived = true`).
- Archived words are hidden from list, detail, exercises, review queue, and
  review history.
- Deleting an already-archived word also returns `200`.
- Re-adding an archived word is treated as a duplicate.

Errors:

| Status | Code | Cause |
|--------|------|-------|
| `404` | `NOT_FOUND` | Word id does not exist |

### 5.7 Regenerate AI content

```http
POST /api/vocabulary/:id/regenerate-ai
```

Success `200`: the full detail response for the word, including regenerated
`aiData`, `aiModel`, `aiUpdatedAt`, `learningState`, and latest 20 `reviews`.

Notes:

- This call is synchronous and can be slow; use the 60-second AI timeout.
- It is the recovery path for words stuck in `PENDING`.
- It uses the stored word, part of speech, and source context as AI input.

Errors:

| Status | Code | Cause |
|--------|------|-------|
| `404` | `NOT_FOUND` | Missing or archived word |
| `500` | `INTERNAL_ERROR` | AI generation or persistence failure |

---

## 6. Review Endpoints

### 6.1 Today's review queue

```http
GET /api/review/today
```

Success `200`:

```json
{
  "success": true,
  "data": {
    "totalDue": 12,
    "newWords": 4,
    "reviewWords": 8,
    "queue": [
      {
        "wordId": "clx0abc123",
        "word": "lexicon",
        "priority": 0.82,
        "knowledgeScore": 0.2,
        "status": "LEARNING",
        "aiReady": true
      }
    ]
  },
  "error": null,
  "meta": null
}
```

Notes:

- `totalDue` is `reviewWords + newWords`.
- Queue items contain exactly the fields shown; they never include `aiData`.
- `queue` is capped at 30 items.
- `newWords` is a count and can be larger than the number of new words in the
  capped queue.
- Queue priority is higher for due/overdue, weak, recently unseen, and new
  words. Treat it as an opaque sort value.

### 6.2 Submit a review answer

```http
POST /api/review/:wordId/submit
Content-Type: application/json
```

Request:

```json
{
  "exerciseId": "clx0abc123-ex-0",
  "userAnswer": "the vocabulary of a language",
  "responseTimeMs": 2300,
  "hintUsed": false,
  "submissionId": "device-submission-123"
}
```

| Field | Required | Rules |
|-------|----------|-------|
| `exerciseId` | Yes | Non-empty string from the exercises response |
| `userAnswer` | Required unless `skipped` is `true` | String |
| `responseTimeMs` | No | Integer `0–60000` |
| `hintUsed` | No | Boolean; defaults to `false` |
| `skipped` | No | Boolean; defaults to `false` |
| `submissionId` | No | Non-empty string; idempotency key |

The client does not send `result` or `exerciseType`. The server derives the
result by comparing the normalized `userAnswer` with the exercise's
`correctAnswer`.

Success `200`:

```json
{
  "success": true,
  "data": {
    "review": {
      "id": "clx0review123",
      "submissionId": "device-submission-123",
      "wordId": "clx0abc123",
      "exerciseType": "MULTIPLE_CHOICE",
      "result": "CORRECT",
      "responseTimeMs": 2300,
      "userAnswer": "the vocabulary of a language",
      "correctAnswer": "the vocabulary of a language",
      "hintUsed": false,
      "createdAt": "2026-11-14T09:20:00.000Z"
    },
    "learningState": {
      "id": "clx0state123",
      "wordId": "clx0abc123",
      "status": "STRONG",
      "knowledgeScore": 0.6847,
      "easeFactor": 2.5,
      "intervalDays": 1,
      "repetitions": 1,
      "nextReviewAt": "2026-11-15T09:20:00.000Z",
      "lastReviewedAt": "2026-11-14T09:20:00.000Z",
      "createdAt": "2026-11-14T09:15:00.000Z",
      "updatedAt": "2026-11-14T09:20:00.000Z"
    },
    "scoreBreakdown": {
      "accuracy": 1,
      "interval": 0.033,
      "responseTime": 0.77,
      "hint": 1,
      "repetition": 0.125
    }
  },
  "error": null,
  "meta": null
}
```

Notes:

- `result` is `CORRECT`, `INCORRECT`, or `SKIPPED`.
- A skipped review does not require `userAnswer`; it schedules a NEW word at
  least one day out.
- `submissionId` makes retries idempotent. Reusing the same key for the same
  word returns the original review and current learning state. Reusing it for a
  different word returns `409 CONFLICT`.
- `nextReviewAt` uses the server's local time plus the computed interval.

Errors:

| Status | Code | Cause |
|--------|------|-------|
| `400` | `VALIDATION_ERROR` | Missing/invalid body fields |
| `400` | `INVALID_EXERCISE` | Exercise does not belong to the word or does not exist |
| `404` | `NOT_FOUND` | Missing or archived word |
| `409` | `AI_NOT_READY` | Word has no AI content |
| `409` | `CONFLICT` | `submissionId` reused for another word |
| `500` | `INTERNAL_ERROR` | Unexpected server failure |

### 6.3 Review history

```http
GET /api/review/history
```

Query parameters:

| Parameter | Type | Default | Rules |
|-----------|------|---------|-------|
| `wordId` | string | none | Filter to one word |
| `page` | integer | `1` | 1–1,000,000 |
| `limit` | integer | `20` | 1–100 |

Success `200`:

```json
{
  "success": true,
  "data": [
    {
      "id": "clx0review123",
      "submissionId": "device-submission-123",
      "wordId": "clx0abc123",
      "exerciseType": "MULTIPLE_CHOICE",
      "result": "CORRECT",
      "responseTimeMs": 2300,
      "userAnswer": "the vocabulary of a language",
      "correctAnswer": "the vocabulary of a language",
      "hintUsed": false,
      "createdAt": "2026-11-14T09:20:00.000Z",
      "word": {
        "word": "lexicon"
      }
    }
  ],
  "error": null,
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "totalPages": 1
  }
}
```

Notes:

- Newest first.
- The `word` relation is an object containing only `word`.
- Archived words are excluded.
- Invalid pagination returns `400 VALIDATION_ERROR`.

---

## 7. Dashboard

```http
GET /api/dashboard
```

Success `200`:

```json
{
  "success": true,
  "data": {
    "todayReview": {
      "due": 8,
      "newWords": 4,
      "needAttention": 2,
      "becomingStrong": 3
    },
    "weakestWords": [
      {
        "wordId": "clx0abc123",
        "word": "lexicon",
        "knowledgeScore": 0.15
      }
    ],
    "stats": {
      "totalWords": 42,
      "new": 4,
      "learning": 12,
      "familiar": 10,
      "strong": 9,
      "mastered": 7,
      "reviewsToday": 5,
      "accuracyLast7Days": 0.8,
      "currentStreak": 0
    }
  },
  "error": null,
  "meta": null
}
```

Notes:

- `weakestWords` contains up to 5 non-archived words with status `LEARNING` or
  `NEW`, ordered by ascending knowledge score.
- `accuracyLast7Days` is a ratio from `0` to `1`; it is `0` when there are no
  reviews in the last 7 days.
- `currentStreak` is currently always `0`.
- The "today" boundary uses the server's local date.

---

## 8. Error Codes and Mobile Mapping

| HTTP | Backend code | Meaning | Mobile failure |
|------|--------------|---------|----------------|
| `400` | `VALIDATION_ERROR` | Invalid body or query | `ValidationFailure` |
| `400` | `INVALID_EXERCISE` | Exercise not found for the word | `ValidationFailure` |
| `404` | `NOT_FOUND` | Word/resource missing or archived | `NotFoundFailure` |
| `409` | `DUPLICATE_WORD` | Word already exists | `DuplicateWordFailure` |
| `409` | `AI_NOT_READY` | AI content is still pending | `AiNotReadyFailure` |
| `409` | `CONFLICT` | State conflict or reused idempotency key | `ConflictFailure` |
| `500` | `INTERNAL_ERROR` | Unexpected server failure | `UnknownFailure` |

Transport-level failures are converted by the mobile data layer:

| Condition | Mobile failure |
|-----------|----------------|
| Timeout | `NetworkFailure` with code `TIMEOUT` |
| Socket/HTTP client failure | `NetworkFailure` with code `NETWORK_ERROR` |
| Malformed success JSON | `UnknownFailure` with code `PARSE_ERROR` |
| Any other unexpected exception | `UnknownFailure` |

The backend's `error.message` is safe to display for validation errors and
duplicates. Network, parse, and 5xx errors should use the app's friendly
messages.

---

## 9. AI Readiness Lifecycle

The backend generates AI content synchronously for up to 8 seconds, then
continues in the background.

| Endpoint | AI behavior |
|----------|-------------|
| `POST /api/vocabulary` single | Waits up to 8 seconds; may return `201` with AI ready or pending |
| `POST /api/vocabulary` bulk | Returns `202` immediately; AI runs in the background |
| `GET /api/vocabulary` | Includes `aiReady` per item |
| `GET /api/vocabulary/:id` | Includes `aiData` and `aiModel` |
| `GET /api/vocabulary/:id/exercises` | `409 AI_NOT_READY` until content exists |
| `POST /api/review/:wordId/submit` | `409 AI_NOT_READY` until content exists |

There is no terminal `FAILED` state. A word can remain `PENDING` after retries.
Recovery options:

- Wait for the background worker.
- Re-read `aiReady`/`aiData`.
- Call `POST /api/vocabulary/:id/regenerate-ai`.

For pending words, the app should eventually poll with backoff and offer a retry
action rather than blocking the user.

---

## 10. Contract Maintenance

When a backend endpoint, field, status code, limit, or error code changes:

1. Update this file in the same change set.
2. Update the affected mobile data source, model, and tests.
3. Verify against backend integration tests or a disposable API call.
4. Update the verified backend commit at the top of this document.
