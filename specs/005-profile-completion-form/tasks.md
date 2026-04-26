# Tasks: Complete Missing User Profile Data

**Input**: Design documents from `/specs/005-profile-completion-form/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Tests**: TDD required by Constitution Principle II — test tasks are included and MUST be written first (Red-Green-Refactor).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to
- Constitution Principle II: write test → confirm FAIL → implement → confirm PASS

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create new models and protocol stubs that all phases depend on. No logic yet.

- [x] T001 [P] Create `AuthUser` model in `BodyMetric/Models/AuthUser.swift` — `Decodable` struct with `id: Int`, `name: String?`, `email: String`, `height: Double?`, `weight: Double?`; add computed `isComplete: Bool` (name non-empty && height > 0 && weight > 0); CodingKeys map to `id`, `name`, `email`, `height`, `weight`
- [x] T002 [P] Create `UpdateProfileRequest` model in `BodyMetric/Models/UpdateProfileRequest.swift` — `Encodable` struct with `name: String`, `email: String`, `height: Double`, `weight: Double`; CodingKeys map to `name`, `email`, `height`, `weight`
- [x] T003 [P] Create `UpdateProfileServiceProtocol` in `BodyMetric/Services/Profile/UpdateProfileServiceProtocol.swift` — `@MainActor protocol UpdateProfileServiceProtocol: AnyObject` with `func updateProfile(_ request: UpdateProfileRequest) async throws -> AuthUser`

**Checkpoint**: All new models and protocols compile. No logic yet — foundation for all stories.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Update the three shared data artifacts (`TokenExchangeResponse`, `UserProfile`, `ProfileStore`) that every user story depends on. All US phases are blocked until this is done.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T004 Write failing tests for `ProfileStore` name field and updated `isComplete` in `BodyMetricTests/Services/ProfileStoreTests.swift` — cover: `save(_ profile: UserProfile)` persists `name`; `isComplete` returns `true` when name/height/weight all present; `isComplete` returns `false` when name nil; `isComplete` returns `false` when height ≤ 0; `isComplete` returns `false` when weight ≤ 0; `clear()` removes name; add `save(from: AuthUser)` overload test
- [x] T005 [P] Update `UserProfile` in `BodyMetric/Models/UserProfile.swift` — add `var name: String?`; add `name` to `CodingKeys` (key `"name"`); add `name` to both `init(from:)` decode and memberwise `init`
- [x] T006 [P] Update `TokenExchangeResponse` in `BodyMetric/Models/TokenExchangeResponse.swift` — add `let user: AuthUser`; add `user` to `CodingKeys` (key `"user"`)
- [x] T007 Update `ProfileStore` in `BodyMetric/Services/Storage/ProfileStore.swift` — add `Key.name = "bm.profile.name"`; add `var name: String? { defaults.string(forKey: Key.name) }`; update `isComplete` to require `name` non-empty + `height > 0` + `weight > 0` (remove `weightUnit`/`heightUnit` from gate); update `save(_ profile: UserProfile)` to also write `name`; add `func save(from user: AuthUser)` overload; update `clear()` to remove `Key.name`
- [x] T008 Verify T004 tests pass against T007 implementation before proceeding

**Checkpoint**: Shared models updated. `ProfileStore.isComplete` includes `name`. `TokenExchangeResponse` carries the user object. All T004 tests pass.

---

## Phase 3: User Story 1 — Profile Completion Gate (Priority: P1) 🎯 MVP

**Goal**: After sign-in, detect missing `name`/`height`/`weight` from the token exchange user object, set `AuthService.needsProfileSetup`, and route the app to `UpdateProfileView` (or `HomeView` if complete). The gate also applies on session restore.

**Independent Test**: Mock `TokenExchangeService` to return a user with `name: nil`. After `authService.signInWithGoogle()`, verify `authService.needsProfileSetup == true` and `ProfileStore.isComplete == false`. Then mock a complete user → verify `needsProfileSetup == false` and `ProfileStore.isComplete == true`.

### Tests for US1

> **Write these tests FIRST — confirm they FAIL before any implementation**

- [x] T009 [P] [US1] Write failing tests for `AuthService.needsProfileSetup` in `BodyMetricTests/Services/AuthServiceTests.swift` — cover: after successful sign-in with complete user (name + height + weight present) → `needsProfileSetup == false` AND `ProfileStore.isComplete == true`; after sign-in with `name: nil` → `needsProfileSetup == true` AND `ProfileStore` NOT saved; after sign-in with `height: 0` → `needsProfileSetup == true`; (use `MockTokenExchangeService`, `MockProfileStore` or test-keyed `ProfileStore`)
- [x] T010 [P] [US1] Write failing tests for `AuthService.restorePreviousSignIn()` with incomplete profile in `BodyMetricTests/Services/AuthServiceTests.swift` — cover: when Google session is restored AND `profileStore.isComplete == false` → `needsProfileSetup == true`; when Google session is restored AND `profileStore.isComplete == true` → `needsProfileSetup == false`

### Implementation for US1

- [x] T011 [US1] Update `AuthServiceProtocol` in `BodyMetric/Services/Auth/AuthServiceProtocol.swift` — add `var needsProfileSetup: Bool { get }`
- [x] T012 [US1] Update `AuthService` in `BodyMetric/Services/Auth/AuthService.swift` — add `private(set) var needsProfileSetup: Bool = false`; in `signInWithGoogle()` after successful token exchange: call `profileStore.save(from: tokenPair.user)` if `tokenPair.user.isComplete`, else `needsProfileSetup = true`; add `profileStore: ProfileStore` to `AuthService.init`; wire `profileStore` in `BodyMetricApp`
- [x] T013 [US1] Update `AuthService.restorePreviousSignIn()` in `BodyMetric/Services/Auth/AuthService.swift` — after restoring Google session + confirming Keychain refresh token present: if `profileStore.isComplete` → `needsProfileSetup = false`; else → `needsProfileSetup = true`
- [x] T014 [US1] Update `BodyMetricApp.authenticatedContainer` in `BodyMetric/App/BodyMetricApp.swift` — replace direct `HomeView` render with: if `authService.needsProfileSetup` → `CreateUserView(...)` (the real form, injecting email + services); else → `HomeView(...)`; pass `authService` reference so form can set `needsProfileSetup = false` on success
- [x] T015 [US1] Verify T009 and T010 tests pass against T011–T013 implementation

**Checkpoint**: Gate is active. Incomplete profile → `UpdateProfileView`. Complete profile → `HomeView`. Session restore respects the gate. All US1 tests pass.

---

## Phase 4: User Story 2 — Form Submission with Loading and Success (Priority: P1)

**Goal**: The user fills in name/height/weight, taps "Update", sees a loading indicator, and on HTTP 201 sees a success message then navigates to `HomeView` after ~4 seconds.

**Independent Test**: Instantiate `UpdateProfileViewModel` with `MockUpdateProfileService` returning 201. Call `submit()` with valid fields. Verify loading state → `isSuccess == true` → `navigationState == .home` after injectable `redirectDelay`.

### Tests for US2

> **Write these tests FIRST — confirm they FAIL before any implementation**

- [x] T016 [P] [US2] Add `MockUpdateProfileService` to `BodyMetricTests/Helpers/TestHelpers.swift` — `@MainActor final class` conforming to `UpdateProfileServiceProtocol`; fields: `responseToReturn: AuthUser`, `shouldThrow: Bool`, `callCount: Int`, `delay: TimeInterval`
- [x] T017 [P] [US2] Write failing tests for `UpdateProfileService` in `BodyMetricTests/Services/UpdateProfileServiceTests.swift` — cover: `updateProfile(_:)` on HTTP 201 decodes and returns `AuthUser`; on non-201 throws `ProfileUpdateError` (define in service); on network error throws; request body contains all four fields; `Authorization: Bearer` header is present (use `MockURLProtocol`)
- [x] T018 [P] [US2] Write failing tests for `UpdateProfileViewModel` (happy path) in `BodyMetricTests/Features/UpdateProfileViewModelTests.swift` — cover: `submit()` with valid fields sets `isLoading = true` then `false`; on success `isSuccess == true`; `navigationState` becomes `.home` after `redirectDelay` (set to `0.05` in tests); button is disabled during loading; `ProfileStore` saved after 201; `authService.needsProfileSetup == false` after success

### Implementation for US2

- [x] T019 [US2] Implement `UpdateProfileService` in `BodyMetric/Services/Profile/UpdateProfileService.swift` — `@MainActor final class UpdateProfileService: UpdateProfileServiceProtocol`; `init(networkClient: NetworkClientProtocol)`; `func updateProfile(_ request: UpdateProfileRequest) async throws -> AuthUser`: encode body as JSON, `POST` to `https://api.bodymetric.com.br/api/users` via `networkClient.data(for:)`; on 201 decode `AuthUser`; on other status throw `ProfileUpdateError.serverError(statusCode)`; on network error throw `ProfileUpdateError.networkError`; injectable `URLSession` not needed (NetworkClient handles it); add `ProfileUpdateError` enum in same file
- [x] T020 [US2] Implement `UpdateProfileViewModel` in `BodyMetric/Features/CreateUser/ViewModels/UpdateProfileViewModel.swift` — `@Observable @MainActor final class`; init receives `email: String`, `updateService: UpdateProfileServiceProtocol`, `profileStore: ProfileStore`, `authService: AuthService`, `redirectDelay: TimeInterval = 4.0`; published: `name: String`, `heightText: String`, `weightText: String`, `isLoading: Bool`, `isSuccess: Bool`, `errorMessage: String?`, `navigationState: ProfileNavigationState` (enum: `.form`, `.home`); `func submit()`: validate → set loading → call service → on 201: `profileStore.save(from:)`, `authService.needsProfileSetup = false`, `isSuccess = true`, sleep `redirectDelay`, `navigationState = .home`; on error: clear loading, set `errorMessage`; trace events: `profile_completion_started`, `profile_completion_succeeded`, `profile_completion_failed` (Principle IV)
- [x] T021 [US2] Replace `CreateUserView` placeholder with real form UI in `BodyMetric/Features/CreateUser/Views/CreateUserView.swift` — `@State private var viewModel: UpdateProfileViewModel`; email field (read-only, pre-filled); name `TextField`; height `TextField` (`.decimalPad`); weight `TextField` (`.decimalPad`); "Update" `Button` at bottom: shows `ProgressView()` when `isLoading`, label "Update" otherwise; button disabled when `isLoading`; success message overlay when `isSuccess`; `errorMessage` shown inline; `navigationBarBackButtonHidden(true)`; no dismiss gesture; `.navigationDestination(isPresented: ...)` to `HomeView` on `navigationState == .home`; all colors from `GrayscalePalette` (Principle VI)
- [x] T022 [US2] Verify T017 and T018 tests pass against T019–T021 implementation

**Checkpoint**: Submit flow works end-to-end. HTTP 201 → success message → `HomeView` after delay. All US2 tests pass.

---

## Phase 5: User Story 3 — Validation and Error Handling (Priority: P2)

**Goal**: Client-side validation blocks submission with invalid data and shows inline messages. Backend errors restore the button and keep the user on the form.

**Independent Test**: Call `UpdateProfileViewModel.submit()` with empty name → verify `errorMessage` is set and `callCount == 0` on `MockUpdateProfileService`. Call `submit()` with name > 20 chars → same. Call `submit()` with valid data against service that throws → verify `isLoading == false`, `errorMessage != nil`, `navigationState == .form`.

### Tests for US3

> **Write these tests FIRST — confirm they FAIL before any implementation**

- [x] T023 [P] [US3] Write failing tests for `UpdateProfileViewModel` validation in `BodyMetricTests/Features/UpdateProfileViewModelTests.swift` — cover: name empty → `errorMessage != nil`, no network call; name > 20 chars → `errorMessage != nil`, no network call; height text non-numeric or ≤ 0 → `errorMessage != nil`, no network call; weight text non-numeric or ≤ 0 → `errorMessage != nil`, no network call; all valid → no validation error, network call made
- [x] T024 [P] [US3] Write failing tests for `UpdateProfileViewModel` backend error recovery in `BodyMetricTests/Features/UpdateProfileViewModelTests.swift` — cover: `shouldThrow = true` → `isLoading == false` after call; `errorMessage != nil`; `isSuccess == false`; `navigationState == .form`; `callCount == 1` (one attempt, not retried); second `submit()` after error resets `errorMessage` and tries again

### Implementation for US3

- [x] T025 [US3] Add validation logic to `UpdateProfileViewModel.submit()` in `BodyMetric/Features/CreateUser/ViewModels/UpdateProfileViewModel.swift` — before network call: `name.trimmingCharacters(in: .whitespaces).isEmpty` → set `errorMessage` and return; `name.count > 20` → set `errorMessage` and return; `Double(heightText) ?? 0 <= 0` → set `errorMessage` and return; `Double(weightText) ?? 0 <= 0` → set `errorMessage` and return; clear `errorMessage` at start of each valid submit
- [x] T026 [US3] Add inline validation error labels to `CreateUserView` in `BodyMetric/Features/CreateUser/Views/CreateUserView.swift` — show `errorMessage` below each relevant field (or as a banner below the form); restore button label on error state (already handled by `isLoading = false` in viewModel); ensure `errorMessage` clears when user edits the field that caused the error
- [x] T027 [US3] Verify T023 and T024 tests pass against T025–T026 implementation

**Checkpoint**: Validation blocks bad data. Backend errors restore the form. All US3 tests pass.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Trace events, security audit, final wiring verification.

- [x] T028 [P] Security audit — grep `Logger` calls in all new/modified files (`AuthUser.swift`, `UpdateProfileService.swift`, `UpdateProfileViewModel.swift`, `CreateUserView.swift`, `AuthService.swift`) and confirm no `name`, `email`, `height`, or `weight` values appear in any log message; only booleans or status codes are permitted (Principles III + VII)
- [x] T029 [P] Verify `UpdateProfileViewModel` emits trace events in `BodyMetric/Features/CreateUser/ViewModels/UpdateProfileViewModel.swift` — `profile_completion_started` before network call, `profile_completion_succeeded` on 201 (no user data in payload), `profile_completion_failed` on error (error category only) (Principle IV)
- [x] T030 [P] Validate `MockHeaderAuthService` and any other `AuthServiceProtocol` stubs in the test target have `needsProfileSetup: Bool` added to conform to the updated protocol
- [ ] T031 [P] Manually validate all quickstart.md scenarios against the running app: incomplete profile gate, complete profile bypass, backend error recovery, client validation, session restore with incomplete profile, in-flight submission lock

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — BLOCKS all user stories
- **Phase 3 (US1)**: Depends on Phase 2 — profile gate and routing
- **Phase 4 (US2)**: Depends on Phase 3 — form needs `needsProfileSetup` wired in `BodyMetricApp`
- **Phase 5 (US3)**: Depends on Phase 4 — validation is added to existing `UpdateProfileViewModel`
- **Phase 6 (Polish)**: Depends on Phases 3–5 complete

### User Story Dependencies

- **US1 (P1)**: Depends on Phase 2 — `AuthService` reads `tokenPair.user`
- **US2 (P1)**: Depends on US1 — `BodyMetricApp` must route to form before form exists
- **US3 (P2)**: Depends on US2 — validation is an extension of the submission flow

### Parallel Opportunities Within Phases

- Phase 1: T001, T002, T003 all parallel (distinct new files)
- Phase 2: T005 and T006 parallel (distinct files); T007 sequential (depends on T005/T006 shapes)
- Phase 3 tests: T009, T010 parallel (same file, different test methods — write sequentially)
- Phase 4 tests: T016, T017, T018 all parallel (distinct files)
- Phase 5 tests: T023, T024 parallel (same file, different methods — write sequentially)
- Phase 6: T028, T029, T030, T031 all parallel

---

## Parallel Example: Phase 4 (US2)

```
Start in parallel:
  Task T016: Add MockUpdateProfileService → BodyMetricTests/Helpers/TestHelpers.swift
  Task T017: Write UpdateProfileService tests → BodyMetricTests/Services/UpdateProfileServiceTests.swift
  Task T018: Write UpdateProfileViewModel happy-path tests → BodyMetricTests/Features/UpdateProfileViewModelTests.swift

Then sequentially (depend on tests failing first):
  Task T019: Implement UpdateProfileService
  Task T020: Implement UpdateProfileViewModel
  Task T021: Replace CreateUserView with real form
  Task T022: Verify T017, T018 pass
```

---

## Implementation Strategy

### MVP First (US1 + US2 — both P1 stories)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 2: Foundational (T004–T008) — CRITICAL, blocks everything
3. Complete Phase 3: US1 — Profile gate (T009–T015)
4. Complete Phase 4: US2 — Submission + loading + success (T016–T022)
5. **STOP and VALIDATE**: Both P1 stories work end-to-end in the simulator
6. Optional: Add Phase 5 (US3 — validation + error handling)

### Incremental Delivery

1. Setup + Foundational → shared models ready
2. US1 → gate is active; users with incomplete profiles see the form
3. US2 → form submits and succeeds; gate closes after success
4. US3 → validation and error recovery complete the UX
5. Polish → trace events and security audit signed off
