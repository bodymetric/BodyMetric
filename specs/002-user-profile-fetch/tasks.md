# Tasks: User Profile Fetch & Display

**Input**: Design documents from `/specs/002-user-profile-fetch/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Organization**: Tasks are grouped by user story to enable independent
implementation and testing of each story.
**Tests**: Included per constitution Principle II (TDD, ≥ 90% coverage).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to

## Path Conventions

All source paths are relative to the Xcode project root:
`/Users/eduardorodrigues/Projects/bodymetric/BodyMetric/`

---

## Phase 1: Setup

**Purpose**: Create directory structure and shared infrastructure for this feature.

- [x] T001 Create directory skeleton: `Models/`, `Services/Profile/`, `Services/Storage/`, `Features/Home/ViewModels/`, `Features/Home/Views/`, `Features/CreateUser/Views/`, `BodyMetricTests/Services/`, `BodyMetricTests/Features/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core types shared across all user stories. MUST be complete before any story phase begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T002 [P] Create `UserProfile` decodable struct (email, weight, weightUnit, height, heightUnit — all optional except email) in `Models/UserProfile.swift`
- [x] T003 [P] Create `ProfileFetchError` enum (userNotFound, unauthorized, serverError, networkError, decodingError) in `Services/Profile/ProfileFetchError.swift`
- [x] T004 [P] Create `UserProfileServiceProtocol` (fetchProfile(email:) async throws → UserProfile) in `Services/Profile/UserProfileServiceProtocol.swift`
- [x] T005 Create `ProfileStore` (UserDefaults-backed read/write for email, weight, weightUnit, height, heightUnit; `isComplete` computed property) in `Services/Storage/ProfileStore.swift`

**Checkpoint**: All shared types exist. User story phases can now begin.

---

## Phase 3: User Story 1 — First Login Profile Hydration (Priority: P1) 🎯 MVP

**Goal**: After a successful Google Sign-In, the app fetches weight + height from
the BodyMetric API using the Google email, persists the data, and displays it
on the home screen.

**Independent Test**: Fresh install → Google Sign-In → home screen shows email,
weight, and height within 3 seconds.

### Tests for User Story 1

> **Write these FIRST — confirm they FAIL before implementation.**

- [x] T006 [P] [US1] Write `UserProfileServiceTests` covering: 200 → UserProfile decoded, 404 → userNotFound thrown, network failure → networkError thrown, decode failure → decodingError thrown — in `BodyMetricTests/Services/UserProfileServiceTests.swift`
- [x] T007 [P] [US1] Write `HomeViewModelTests` covering: complete cache → no fetch triggered, incomplete cache → fetchProfile called, 200 → properties populated, 404 → navigationState == .createUser — in `BodyMetricTests/Features/HomeViewModelTests.swift`

### Implementation for User Story 1

- [x] T008 [P] [US1] Implement `UserProfileService` (URLSession GET to `https://api.bodymetric.com.br/api/users?email=`, map 200/404/4xx/5xx to `ProfileFetchError`, decode `UserProfileResponse`, timeout 10 s, log status at INFO — no email in log) in `Services/Profile/UserProfileService.swift`
- [x] T009 [P] [US1] Implement `HomeViewModel` (`@Observable @MainActor`; holds `email`, `weight`, `weightUnit`, `height`, `heightUnit`, `isLoading`, `errorMessage`, `navigationState`; `loadProfile()` reads `ProfileStore.isComplete` — if false calls `UserProfileService.fetchProfile`, if true returns cache; logs `profile_cached_hit` or `profile_fetch_started`) in `Features/Home/ViewModels/HomeViewModel.swift`
- [x] T019 [US1] Add interaction trace events to `HomeViewModel`: `profile_fetch_started` (with session_id, no email), `profile_fetch_succeeded`, `profile_fetch_404`, `profile_cached_hit` — stub calls until Tracer is wired; US1 is NOT complete without these stubs in place in `Features/Home/ViewModels/HomeViewModel.swift`
- [x] T010 [US1] Implement `HomeView` (grayscale; VStack showing email label, weight + unit label, height + unit label; `ProgressView` while `isLoading`; navigate to `CreateUserView` when `navigationState == .createUser`) in `Features/Home/Views/HomeView.swift`
- [x] T011 [US1] Update `AuthService` to expose `authenticatedEmail: String?` (reads `GIDSignIn.sharedInstance.currentUser?.profile?.email` after sign-in and after `restorePreviousSignIn`) in `Services/Auth/AuthService.swift` and `Services/Auth/AuthServiceProtocol.swift`
- [x] T012 [US1] Update `BodyMetricApp` to instantiate `HomeViewModel(email: authService.authenticatedEmail)` and navigate to `HomeView` (replacing `authenticatedPlaceholder`) after `isAuthenticated == true` in `App/BodyMetricApp.swift`

**Checkpoint**: US1 fully functional. Google Sign-In → API fetch → data on home screen.

---

## Phase 4: User Story 2 — Returning User with Missing Profile Data (Priority: P2)

**Goal**: On session restore, if weight or height is absent from local storage,
the app automatically re-fetches from the API. 404 navigates to CreateUserView.

**Independent Test**: Pre-populate local storage with only email (no weight/height)
→ launch app → app re-fetches → home screen shows weight and height.

### Tests for User Story 2

> **Write these FIRST — confirm they FAIL before implementation.**

- [x] T013 [P] [US2] Write `ProfileStoreTests` covering: `isComplete` returns false when weight or height missing, returns true when all fields present, `save()` and `clear()` round-trip correctly — in `BodyMetricTests/Services/ProfileStoreTests.swift`

### Implementation for User Story 2

- [x] T014 [P] [US2] Implement `CreateUserView` placeholder (grayscale; static message "Your profile was not found. Please try again or contact support."; back/sign-out button) in `Features/CreateUser/Views/CreateUserView.swift`
- [x] T015 [US2] Update `HomeViewModel.loadProfile()` to handle `ProfileFetchError.userNotFound` by setting `navigationState = .createUser` and logging `profile_fetch_404` trace event in `Features/Home/ViewModels/HomeViewModel.swift`
- [x] T016 [US2] Verify `BodyMetricApp` passes restored-session email into `HomeViewModel` so the re-fetch path triggers correctly on session restore in `App/BodyMetricApp.swift`

**Checkpoint**: Returning users with incomplete cache self-heal automatically.
404 users land on CreateUserView.

---

## Phase 5: User Story 3 — Home Screen Profile Display (Priority: P3)

**Goal**: Home screen always shows email + weight + height, or a clear
placeholder when data is still loading or unavailable.

**Independent Test**: Pre-populate ProfileStore with known values → launch →
verify home screen renders all three fields with correct units and layout.

### Implementation for User Story 3

- [x] T017 [P] [US3] Add loading skeleton / placeholder text ("–– kg", "–– cm") to `HomeView` for when weight or height is nil; ensure `isLoading` state shows `ProgressView` over the metric area in `Features/Home/Views/HomeView.swift`
- [x] T018 [US3] Add error banner row to `HomeView` that shows `errorMessage` when non-nil (grayscale warning icon + text; dismissible) in `Features/Home/Views/HomeView.swift`

**Checkpoint**: Home screen handles all states: loading, loaded, partial, error.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Grayscale compliance and PII log audit across all stories.

- [x] T020 [P] Verify all `HomeView` and `CreateUserView` UI elements use only `GrayscalePalette` tokens; no hardcoded `Color` values — review `Features/Home/Views/HomeView.swift` and `Features/CreateUser/Views/CreateUserView.swift`
- [x] T021 Review error logging in `UserProfileService` and `HomeViewModel`: confirm no email or PII appears in any log message; redact if found — `Services/Profile/UserProfileService.swift`, `Features/Home/ViewModels/HomeViewModel.swift`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — **BLOCKS all user stories**
- **Phase 3 (US1)**: Depends on Phase 2 completion; no dependency on US2/US3
- **Phase 4 (US2)**: Depends on Phase 2 + Phase 3 (US1 wired HomeViewModel reused)
- **Phase 5 (US3)**: Depends on Phase 3 (HomeView exists)
- **Phase 6 (Polish)**: Depends on Phases 3–5 complete

### Within Each Phase

- Tests (T006, T007, T013) MUST be written and FAIL before their paired implementation tasks
- Models/protocols (T002–T004) before services (T008)
- ProfileStore (T005) before HomeViewModel (T009)
- HomeViewModel (T009) before HomeView (T010)
- AuthService update (T011) before BodyMetricApp wiring (T012)

### Parallel Opportunities

Within Phase 2: T002, T003, T004 can run in parallel; T005 after any of them.
Within Phase 3: T006 + T007 + T008 + T009 can all start in parallel after Phase 2.
Within Phase 4: T013 + T014 can run in parallel; T015 + T016 after T013.
Within Phase 6: T020 + T021 can run in parallel.

---

## Parallel Example: User Story 1

```text
# Write tests and implement service + ViewModel simultaneously (Phase 3):
Task T006: UserProfileServiceTests
Task T007: HomeViewModelTests
Task T008: UserProfileService implementation
Task T009: HomeViewModel implementation

# All four above can run in parallel — different files, no dependencies.
# Then sequentially:
Task T010: HomeView (needs HomeViewModel)
Task T011: AuthService email exposure
Task T012: BodyMetricApp wiring (needs T010 + T011)
```

---

## Implementation Strategy

### MVP (User Story 1 Only)

1. Phase 1: Setup directory structure
2. Phase 2: Foundational types (T002–T005)
3. Phase 3: Full US1 flow (T006–T012)
4. **STOP and VALIDATE**: Sign in → API fetch → home screen shows data ✅
5. Demo / deploy on device

### Incremental Delivery

1. Phase 1 + 2 → foundation ready
2. Phase 3 (US1) → home screen with live data (MVP)
3. Phase 4 (US2) → self-healing on relaunch + 404 create-user flow
4. Phase 5 (US3) → polished loading/error states
5. Phase 6 → observability + compliance hardening

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- Commit after each task using Gitmoji prefix (per constitution v3.1.0)
- Stop at each phase checkpoint to validate the story independently
- Avoid: vague tasks, same-file conflicts, cross-story dependencies that break independence
