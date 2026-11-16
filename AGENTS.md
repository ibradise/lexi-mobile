# AGENTS.md — Mobile Development Guide

> This file is the first thing a coding agent reads when working in this repo.

---

## Project Overview

Lexi mobile app — Flutter application for the Lexi vocabulary learning app.

**What it does:** Allows users to add vocabulary words, review them through quizzes, and track their learning progress.

---

## MANDATORY WORKFLOW (do not skip)

### Before Building
1. Read `../prd/WORKFLOW.md` — this is how we work
2. Read `../prd/requirements.md` — what to build
3. Read `../prd/architecture.md` — system flow
4. Read `docs/tasks.md` — what's next
5. Read `docs/architecture.md` — current code structure
6. Read `docs/api-contract.md` — exact backend request/response contract
7. Read `docs/screens.md` — screen behavior and navigation

### After Building
8. Update `docs/IMPLEMENTATION.md` — what was actually built
9. Update `docs/architecture.md` — if code structure changed
10. Update `docs/api-contract.md` — if the backend contract changed
11. **STOP and ask the user** for approval before clearing `docs/tasks.md`
12. After approval, clear `docs/tasks.md`
13. Commit only if this repository has been initialized with git

**DO NOT** clear `docs/tasks.md` automatically or immediately.
**ALWAYS** wait for explicit user approval before clearing.
**DO NOT** start the next phase until all steps are done.

---

## Rules

### DO
- Read `../prd/WORKFLOW.md`, `../prd/requirements.md`, and `../prd/architecture.md` before starting work
- Read `docs/tasks.md` and `docs/architecture.md` before starting work
- Use Flutter's built-in `Navigator` for navigation
- Follow Clean Architecture with global layers: `data/`, `domain/`, `presentation/`
- Build features as vertical slices through the global layers
- Keep `domain/` independent of Flutter, `http`, and all other layers
- Use Bloc (`flutter_bloc`) — BLoC for screens and Cubit for trivial local state
- Use manual GetIt for dependency injection
- Inject dependencies through constructors
- Use the `http` package through the centralized `ApiClient`
- Keep data models separate from domain entities
- Create one use case per meaningful application operation
- Translate low-level exceptions into `AppFailure` in repositories
- Write tests with `flutter_test`, `bloc_test`, and `mocktail`
- Follow existing code conventions
- Update `docs/IMPLEMENTATION.md` after building
- Update `docs/architecture.md` if the code structure changes

### DO NOT
- **DO NOT implement anything from `../prd/proposals/`** — they are not approved
- Do NOT add authentication (not in MVP)
- Do NOT add new dependencies without asking
- Do NOT add a third-party routing package — use Flutter's built-in `Navigator`
- Do NOT use hardcoded colors (use the theme)
- Do NOT put business logic in widgets
- Do NOT call GetIt directly inside BLoCs — use constructor injection
- Do NOT expose raw HTTP exceptions or status codes to the UI
- Do NOT import `http`, `data/`, or `presentation/` from `domain/`
- **DO NOT install outdated or RC versions of packages** — always install the latest stable version
- **DO NOT guess or assume any real-time data** — always use the websearch tool to verify latest versions, APIs, documentation, or any information from the internet

---

## Commands

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze

# Build APK
flutter build apk --debug
```

---

## Project Structure

```
lexi-mobile/
├── lib/
│   ├── core/
│   │   ├── config/
│   │   ├── di/
│   │   ├── network/
│   │   ├── error/
│   │   └── utils/
│   ├── data/
│   │   ├── datasources/
│   │   ├── models/
│   │   └── repositories/
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   ├── presentation/
│   │   ├── bloc/
│   │   ├── pages/
│   │   ├── widgets/
│   │   └── navigation/
│   └── main.dart
├── test/
├── pubspec.yaml
└── analysis_options.yaml
```

No feature subfolders. Features are vertical slices through the global layers.

---

## Design Principles

- Light theme with an off-white background (`#F7F6F2`), purple accent (`#6C63FF`), and dark text
- Glassmorphism aesthetic added in later UI phases
- Smooth animations and transitions
- Loading states for all async operations
- Empty states for lists
- Error states with retry options

---

## Technical Architecture

### Tech Stack

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

### Layer Responsibilities

- `core/network/ApiClient` — transport only: base URL, headers, JSON, envelope, timeouts
- `data/datasources` — endpoint-specific request and response handling; JSON → models
- `data/repositories` — implement domain interfaces; models → entities; exceptions → `AppFailure`
- `domain/usecases` — one meaningful operation; validation; call repository interfaces
- `presentation/bloc` — state transitions; call use cases; catch `AppFailure`
- `presentation/pages` and `presentation/widgets` — render state; dispatch events only

### Navigation

Use Flutter's built-in `Navigator` with centralized named routes. Route definitions and
navigation helpers live in `presentation/navigation/`, using `onGenerateRoute` for typed
route arguments. Do not add a third-party routing package.

### State Management

- Use `Bloc<Event, State>` for screen-level state.
- Use `Cubit` only for trivial local state.
- Events and states extend `Equatable`.
- Keep business logic out of widgets — widgets add events only.
- Receive use cases through BLoC constructors.

### Error Handling

- Only repositories construct `AppFailure`.
- BLoCs catch `AppFailure` and emit error states.
- Unexpected exceptions are logged with stack traces and mapped to `UnknownFailure`.
- The UI never sees `ApiException`, HTTP status codes, or raw backend responses.
