# Tasks: New Plan Wizard — Day Selection Screen

**Input**: Design documents from `/specs/008-wizard-day-selection/`  
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Tests**: Included — required by Constitution Principle II (TDD, ≥ 90% coverage mandatory). Write tests first; verify they FAIL before implementing.

**Organization**: Tasks grouped by user story for independent delivery.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no shared dependencies)
- **[Story]**: US1 / US2 / US3
- All new Swift files must be registered in the **BodyMetric** target in `BodyMetric.xcodeproj`

---

## Phase 1: Setup

**Purpose**: Create the `Services/WorkoutPlan/` directory so all subsequent tasks have a stable target path.

- [x] T001 Create directory `Services/WorkoutPlan/` at the project root and add the corresponding Xcode group to `BodyMetric.xcodeproj` (use the `Services/Profile/` group as reference for placement)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Service layer models, error type, protocol, and concrete service. All three user stories depend on these compiling before any ViewModel or View work can begin.

**⚠️ CRITICAL**: Do not start any story phase until T002–T007 are complete and compiling.

### Tests (write first — must FAIL before T004–T007)

- [x] T002 [P] Write failing unit tests in `BodyMetricTests/Services/WorkoutPlanServiceTests.swift` (add file + register in BodyMetricTests target): test `fetchDays` 200 → returns decoded `[WorkoutPlanDayResponse]`; test `fetchDays` 404 → throws `WorkoutPlanError.notFound`; test `fetchDays` 500 → throws `WorkoutPlanError.serverError(500)`; test `fetchDays` malformed JSON → throws `WorkoutPlanError.decodingError`; test `saveDays` 201 → returns without throwing; test `saveDays` 400 → throws `WorkoutPlanError.serverError(400)`; use a `MockNetworkClient` (stub `NetworkClientProtocol`)
- [x] T003 [P] Add failing test cases to `BodyMetricTests/Features/NewPlanViewModelTests.swift`: test `loadDays` success (mocked service returns Sunday) → `loadState == .loaded` and `selectedDays == {.sunday}`; test `loadDays` 404 → `loadState == .empty` and `selectedDays.isEmpty`; test `loadDays` generic error → `loadState == .failed(...)` and `selectedDays.isEmpty`; test `saveDays` success → `onSuccess` called and `isSaving == false`; test `saveDays` failure → `saveErrorMessage != nil` and `isSaving == false`; define `MockWorkoutPlanService` conforming to `WorkoutPlanServiceProtocol` for isolation

### Implementation (models → error → protocol → service)

- [x] T004 [P] Create `Models/WorkoutPlanModels.swift`: define `WorkoutPlanDayResponse: Codable, Identifiable` with fields `planId: Int`, `plannedWeekNumber: Int`, `plannedDayOfWeek: String`, `executionCount: Int`, `dayNames: [String]`, `totalExercises: Int`, `totalSets: Int`, `estimatedDurationMinutes: Int` (id = planId); define `WorkoutPlanDayRequest: Codable` with fields `plannedWeekNumber: String` and `plannedDayOfWeek: String`; register in BodyMetric target
- [x] T005 [P] Create `Services/WorkoutPlan/WorkoutPlanError.swift`: define `WorkoutPlanError: LocalizedError` with cases `notFound`, `serverError(Int)`, `decodingError`, `networkError(Error)`; `errorDescription` returns user-facing messages (no PII); register in BodyMetric target
- [x] T006 Create `Services/WorkoutPlan/WorkoutPlanServiceProtocol.swift`: `@MainActor protocol WorkoutPlanServiceProtocol: AnyObject` with `func fetchDays() async throws -> [WorkoutPlanDayResponse]` and `func saveDays(_ days: [WorkoutPlanDayRequest]) async throws`; register in BodyMetric target; depends on T004, T005
- [x] T007 Create `Services/WorkoutPlan/WorkoutPlanService.swift`: `@MainActor final class WorkoutPlanService: WorkoutPlanServiceProtocol`; `private let networkClient: any NetworkClientProtocol`; `private static let baseURL = "https://api.bodymetric.com.br/api/workout-plans"`; `fetchDays()`: builds GET `URLRequest(url:)`, calls `networkClient.data(for:)`, handles `200` → `JSONDecoder().decode([WorkoutPlanDayResponse].self, from: data)`, `404` → throws `WorkoutPlanError.notFound`, other → throws `WorkoutPlanError.serverError(statusCode)`; `saveDays(_:)`: builds POST `URLRequest` with `Content-Type: application/json` and `JSONEncoder().encode(days)` as body, handles `201` → return normally, other → throws `WorkoutPlanError.serverError(statusCode)`; `Logger.error` at every `catch` site (no tokens in logs); register in BodyMetric target; run T002 — all tests must pass; depends on T004, T005, T006

**Checkpoint**: Service layer compiles and T002 passes. Story implementation can now begin.

---

## Phase 3: User Story 1 — Select days and advance to next wizard step (Priority: P1) 🎯 MVP

**Goal**: A first-time user opens the wizard day selection screen, selects at least one day, taps Continue, and reaches the second wizard step.

**Independent Test**: Open wizard with a mock service returning empty (no prior days), tap Monday, tap Continue, verify step 2 of the wizard is presented.

### Tests for US1 (write first — must FAIL before T009–T015)

- [x] T008 Write failing UI test stub in `BodyMetricUITests/DaySelectionUITests.swift`: test P1 journey — tap "Open menu" → tap "New Workout Plan" → wizard opens → (mocked days = empty) → tap Monday row → tap Continue → verify `newPlanWizard` shows step 2 content; add `XCTSkipIf` for CI environment; register in BodyMetricUITests target

### Implementation for US1

- [x] T009 Add `DayOfWeek.toRequest: WorkoutPlanDayRequest` extension at the bottom of `Features/NewPlan/Models/NewPlanModels.swift`: `WorkoutPlanDayRequest(plannedWeekNumber: String(rawValue), plannedDayOfWeek: fullLabel.lowercased())`; depends on T004
- [x] T010 [US1] Modify `Features/NewPlan/ViewModels/NewPlanViewModel.swift`: add nested `enum SelectDaysLoadState: Equatable` with cases `idle`, `loading`, `loaded`, `empty`, `failed(String)`; add `var loadState: SelectDaysLoadState = .idle`; add `var isSaving: Bool = false`; add `var saveErrorMessage: String? = nil`; add `func loadDays(using service: any WorkoutPlanServiceProtocol) async` — sets `.loading`, calls `service.fetchDays()`, on success maps `plannedWeekNumber` to `DayOfWeek(rawValue:)` and sets `selectedDays`, sets `.loaded` or `.empty`, catches `WorkoutPlanError.notFound` → `.empty`, catches other → `.failed(error.localizedDescription)`, always logs state transition; add `func saveDays(using service: any WorkoutPlanServiceProtocol, onSuccess: @MainActor @Sendable () -> Void) async` — guards against `isSaving`, sets `isSaving = true`, clears `saveErrorMessage`, calls `service.saveDays(orderedSelectedDays.map(\.toRequest))`, on success calls `onSuccess()`, on failure sets `saveErrorMessage`; Logger.info traces per quickstart.md; run T003 — all tests must pass; depends on T006, T009
- [x] T011 [US1] Modify `Features/NewPlan/Views/Components/SelectDaysStepView.swift`: add `let service: any WorkoutPlanServiceProtocol` parameter; add `.task { await viewModel.loadDays(using: service) }` to the root view; replace static day list with a loading overlay (`ProgressView` + dimmed background) when `viewModel.loadState == .loading`; add inline error banner (`GrayscalePalette.surface` background + warning SF Symbol + `GrayscalePalette.primary` text) below the day list when `viewModel.saveErrorMessage != nil`; clear `saveErrorMessage` in the tap action of each day row; all colors via `GrayscalePalette` only; depends on T010
- [x] T012 [US1] Modify `Features/NewPlan/Views/NewPlanWizardView.swift`: add `let service: any WorkoutPlanServiceProtocol` parameter; change the Continue button action on step 1 from direct `viewModel.advance()` to `Task { await viewModel.saveDays(using: service) { viewModel.advance() } }`; add `viewModel.isSaving` as an additional disabled condition on the Continue button (alongside `!viewModel.isStepValid(1)`); pass `service` to `SelectDaysStepView`; depends on T011
- [x] T013 [P] [US1] Modify `Features/Navigation/MainTabView.swift`: add `let networkClient: any NetworkClientProtocol` parameter to the struct; pass `networkClient` through to `TodayView(workout:streak:userName:networkClient:)`
- [x] T014 [US1] Modify `Features/Workout/Views/TodayView.swift`: add `let networkClient: any NetworkClientProtocol` parameter; in the `.fullScreenCover(isPresented: $showWizard)` closure, change `NewPlanWizardView()` to `NewPlanWizardView(service: WorkoutPlanService(networkClient: networkClient))`; depends on T013
- [x] T015 [US1] Modify `App/BodyMetricApp.swift`: in `authenticatedContainer`, pass `networkClient` to `MainTabView(homeViewModel:authService:profileStore:networkClient:)`; depends on T014

**Checkpoint**: User Story 1 fully functional. Open wizard → fetch (empty) → select days → Continue → POST 201 → step 2 appears.

---

## Phase 4: User Story 2 — Pre-fill selections from a previous plan (Priority: P2)

**Goal**: A returning user opens the screen and sees their previously saved days already checked.

**Independent Test**: Mock service returning `[WorkoutPlanDayResponse(planId:7, plannedWeekNumber:7, ...)]`, open SelectDaysStepView, verify Sunday checkbox is pre-selected and all others are unchecked.

### Tests for US2 (add to existing test file)

- [x] T016 [P] [US2] Add test cases to `BodyMetricTests/Features/NewPlanViewModelTests.swift`: test `loadDays` with mock returning Sunday-only → `selectedDays == {.sunday}` and `loadState == .loaded`; test `loadDays` with mock returning Monday+Friday → `selectedDays == {.monday, .friday}`; test `loadDays` with invalid `plannedWeekNumber` (e.g., 0 or 8) → those entries are ignored, no crash

### Implementation for US2

- [x] T017 [US2] Verify `NewPlanViewModel.loadDays` correctly uses `DayOfWeek(rawValue:)` which returns `nil` for out-of-range values (1–7 only); ensure the `compactMap` in `loadDays` silently skips any invalid week numbers without crashing; no code change needed if T010 implemented correctly — validate and add comment explaining the nil-safe mapping; run T016 — all tests must pass

**Checkpoint**: User Stories 1 AND 2 independently functional.

---

## Phase 5: User Story 3 — Recover from a failed save (Priority: P3)

**Goal**: When the POST fails, the user sees a clear error message, stays on the day selection screen, and can retry.

**Independent Test**: Mock service `saveDays` throws `WorkoutPlanError.serverError(500)`, tap Continue, verify error banner appears, verify day selection is unchanged, tap Continue again, verify service is called a second time.

### Tests for US3 (add to existing test file)

- [x] T018 [P] [US3] Add test cases to `BodyMetricTests/Features/NewPlanViewModelTests.swift`: test `saveDays` failure → `saveErrorMessage` is a non-empty user-facing string; test that `selectedDays` is unchanged after `saveDays` failure; test that toggling a day after an error clears `saveErrorMessage`; test that calling `saveDays` again after failure retries the service call

### Implementation for US3

- [x] T019 [US3] Verify `SelectDaysStepView` dismisses the error banner when a day is toggled: the `viewModel.saveErrorMessage = nil` clear must be in the day-toggle tap action (already added in T011 — validate and add dedicated comment); verify the error banner text (`viewModel.saveErrorMessage`) propagates to the UI correctly; run T018 — all tests must pass

**Checkpoint**: All three user stories independently functional.

---

## Final Phase: Polish & Cross-Cutting Concerns

- [x] T020 [P] Verify all new Swift files (`WorkoutPlanModels.swift`, `WorkoutPlanError.swift`, `WorkoutPlanServiceProtocol.swift`, `WorkoutPlanService.swift`, `WorkoutPlanServiceTests.swift`, `DaySelectionUITests.swift`) are registered in the correct Xcode targets; confirm build succeeds: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'`
- [x] T021 [P] Audit Logger.info/error calls against quickstart.md trace event table: confirm `wizard_days_load_started`, `wizard_days_load_success`, `wizard_days_load_empty`, `wizard_days_load_failed`, `wizard_days_save_started`, `wizard_days_save_success`, `wizard_days_save_failed` are all present in `NewPlanViewModel.swift`
- [x] T022 [P] Audit Constitution VI compliance: `grep -rn "Color(" Services/WorkoutPlan/ Features/NewPlan/` — confirm zero raw `Color(red:green:blue:)` values; all structural colors use `GrayscalePalette.*`
- [x] T023 Run full test suite with coverage: `xcodebuild test -scheme BodyMetric -enableCodeCoverage YES -destination 'platform=iOS Simulator,name=iPhone 16'`; confirm ≥ 90% line+branch coverage across `WorkoutPlanService.swift`, `WorkoutPlanError.swift`, and the new `NewPlanViewModel` methods; add targeted tests for any uncovered branches

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — **blocks all story phases**
- **Phase 3 (US1)**: Depends on Phase 2 (T006, T007 must compile)
- **Phase 4 (US2)**: Depends on T010 (loadDays implemented) — can overlap with late Phase 3 tasks
- **Phase 5 (US3)**: Depends on T010 + T011 (saveDays + error banner exist) — can overlap with Phase 4
- **Final Phase**: Depends on all story phases complete

### Within Phase 3

| Task | Depends on |
|------|-----------|
| T009 | T004 (WorkoutPlanDayRequest must exist) |
| T010 | T006, T009 |
| T011 | T010 |
| T012 | T011 |
| T013 | (independent - just adds parameter) |
| T014 | T013, T012 |
| T015 | T014 |

T013 (MainTabView parameter addition) can start in parallel with T009–T012 since it touches a different file.

---

## Parallel Opportunities

### Phase 2 Parallel Batch

```
Batch A (write tests, verify FAIL):
  T002: WorkoutPlanServiceTests.swift
  T003: NewPlanViewModelTests.swift (additions)

Batch B (implement foundation):
  T004: WorkoutPlanModels.swift
  T005: WorkoutPlanError.swift
  [then sequentially: T006 → T007]
```

### Phase 3 Parallel Batch

```
T013 (MainTabView): can run in parallel with T009/T010/T011/T012
T009 → T010 → T011 → T012 (sequential)
T014 → T015 (sequential, after T013 and T012)
```

---

## Implementation Strategy

### MVP (User Story 1 only)

1. Phase 1: T001 (setup)
2. Phase 2: T002 → T003 → T004+T005 → T006 → T007 (foundation)
3. Phase 3: T008 → T009 → T010 → T011 → T012 → T013 → T014 → T015 (US1)
4. **STOP**: Verify: open wizard → (no prior data) → select Monday → Continue → POST → step 2 appears
5. Final: T020–T023

### Full Delivery

1. MVP above (US1)
2. Phase 4 (US2): T016 → T017 — verify pre-fill works
3. Phase 5 (US3): T018 → T019 — verify error handling works
4. Final phase

---

## Notes

- `[P]` tasks touch different files — no shared mutable state; safe to assign to parallel agents
- TDD is mandatory (Principle II): every test listed must FAIL before its corresponding implementation task is started
- The `NetworkClient` already injects `Authorization: Bearer` — **no new auth code needed** (Principle VII)
- `plannedWeekNumber` is **String** in POST body, **Int** in GET response — two separate Codable types (T004)
- Commit after each task: `✨ T010: add loadDays/saveDays to NewPlanViewModel`
