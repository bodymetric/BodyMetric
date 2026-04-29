# Tasks: Workout Plan Wizard — Step 2 Day & Exercise Persistence

**Input**: Design documents from `/specs/011-wizard-day-persist/`  
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Tests**: Included — required by Constitution Principle II (TDD, ≥ 90% coverage).  
Write tests first; verify they FAIL before implementing.

**Organization**: Tasks grouped by user story for independent delivery.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1 / US2 / US3
- All new Swift files must be registered in `BodyMetric.xcodeproj` (BodyMetric target)
- All new test files registered in `BodyMetricTests` target

---

## Phase 1: Setup

**Purpose**: Create the `Models/WorkoutDayPlanModels.swift` file and the two new service files so all subsequent tasks have a stable target path.

- [x] T001 Create placeholders (empty Swift files with just `import Foundation`) at: `Models/WorkoutDayPlanModels.swift`, `Services/WorkoutPlan/WorkoutDayPlanServiceProtocol.swift`, `Services/WorkoutPlan/WorkoutDayPlanService.swift`, `BodyMetricTests/Services/WorkoutDayPlanServiceTests.swift` — then register all four in `BodyMetric.xcodeproj` (first three in BodyMetric target; last in BodyMetricTests target)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: DTOs, service protocol, concrete service, and the backward-compatible change to `WorkoutPlanService.saveDays`. All user stories depend on these compiling.

**⚠️ CRITICAL**: Do not start any story phase until T002–T009 are complete and the build succeeds.

### Tests (write first — must FAIL before T005–T009)

- [x] T002 [P] Write failing unit tests in `BodyMetricTests/Services/WorkoutDayPlanServiceTests.swift`: test `saveDayPlan` 201 → returns `WorkoutDayPlanResponse` with correct `workoutDayPlanId`; test `saveDayPlan` 404 → throws `WorkoutPlanError.serverError(404)`; test `saveDayPlan` 500 → throws `WorkoutPlanError.serverError(500)`; test `saveExerciseBlock` 201 → no throw; test `saveExerciseBlock` 400 → throws `WorkoutPlanError.serverError(400)`; test `saveDayPlan` sends correct path (`/api/workout-plans/{id}/days`) in the request URL; test `saveExerciseBlock` sends correct path (`/api/workout-day-plans/{id}/exercise-blocks`); use `MockNetworkClient` from `TestHelpers.swift`
- [x] T003 [P] Update `BodyMetricTests/Services/WorkoutPlanServiceTests.swift`: change `test_saveDays_201_doesNotThrow` to assert returned array is non-nil; change `test_saveDays_201_sendsCorrectJSONBody` to also verify the 201 response body is decoded; add `test_saveDays_201_returnsDecodedDayResponses` that verifies the returned `[WorkoutPlanDayResponse]` contains the expected `planId` values
- [x] T004 [P] Add failing tests to `BodyMetricTests/Features/NewPlanViewModelTests.swift` in a new `NewPlanViewModelDayConfigTests` class: test `saveDays` success → `workoutPlanIds` populated from response (`day → planId`); test `saveDayConfig` success → `onSuccess` called, `isDayConfigSaving == false`, `dayConfigSaveError == nil`; test `saveDayConfig` day-plan failure → `dayConfigSaveError != nil`, `isDayConfigSaving == false`, advance NOT called; test `saveDayConfig` exercise-block failure → `dayConfigSaveError != nil`, `isDayConfigSaving == false`, advance NOT called; use `MockWorkoutPlanService` and a new `MockWorkoutDayPlanService`

### Implementation

- [x] T005 [P] Populate `Models/WorkoutDayPlanModels.swift`: define `WorkoutDayPlanRequest: Codable` with fields `name: String`, `orderIndex: Int`, `isActive: Bool`; define `WorkoutDayPlanResponse: Decodable, Identifiable` with field `workoutDayPlanId: Int` (id = workoutDayPlanId; additional response fields ignored); define `ExerciseBlockPlanRequest: Codable` with fields `exerciseId: String`, `targetReps: Int`, `targetWeightKg: Double`, `restSeconds: Int` — add `CodingKeys` mapping with a comment `// ⚠️ Verify field names against live API`; add convenience `init(block: ExerciseBlock)` that maps from existing `ExerciseBlock` type; register in BodyMetric target
- [x] T006 Update `Services/WorkoutPlan/WorkoutPlanServiceProtocol.swift`: change `func saveDays(_ days: [WorkoutPlanDayRequest]) async throws` to `func saveDays(_ days: [WorkoutPlanDayRequest]) async throws -> [WorkoutPlanDayResponse]`; update the docstring to note that the return value contains `planId` per day for use in step 2
- [x] T007 Update `Services/WorkoutPlan/WorkoutPlanService.swift`: in `saveDays(_:)`, change the `(_, http) = try await networkClient.data(for: request)` call to capture `(data, http)`; after the `guard http.statusCode == 201` check, add decode call `return try decodeArray(data: data)`; add private `decodeArray(data: Data) throws -> [WorkoutPlanDayResponse]` helper that decodes `[WorkoutPlanDayResponse].self`; run T003 — tests must pass; depends on T005, T006
- [x] T008 [P] Populate `Services/WorkoutPlan/WorkoutDayPlanServiceProtocol.swift`: define `@MainActor protocol WorkoutDayPlanServiceProtocol: AnyObject` with `func saveDayPlan(workoutPlanId: Int, request: WorkoutDayPlanRequest) async throws -> WorkoutDayPlanResponse` and `func saveExerciseBlock(workoutDayPlanId: Int, request: ExerciseBlockPlanRequest) async throws`; register in BodyMetric target; depends on T005
- [x] T009 Populate `Services/WorkoutPlan/WorkoutDayPlanService.swift`: `@MainActor final class WorkoutDayPlanService: WorkoutDayPlanServiceProtocol`; `private let networkClient: any NetworkClientProtocol`; `private static let baseURL = "https://api.bodymetric.com.br/api"`; `saveDayPlan(workoutPlanId:request:)` → builds POST URLRequest to `{baseURL}/workout-plans/{workoutPlanId}/days`, encodes request body as JSON, calls `networkClient.data(for:)`, handles 201 → decode + return `WorkoutDayPlanResponse`, other → throw `WorkoutPlanError.serverError(statusCode)`; `saveExerciseBlock(workoutDayPlanId:request:)` → builds POST to `{baseURL}/workout-day-plans/{workoutDayPlanId}/exercise-blocks`, encodes body, handles 201 → return, other → throw; `Logger.error` at all catch sites (no tokens/PII); register in BodyMetric target; run T002 — all tests must pass; depends on T005, T008

**Checkpoint**: All foundational tests pass (T002, T003, T004 fail→pass). Build succeeds. Story phases can begin.

---

## Phase 3: User Story 1 — Name a training day, add exercises, and save to advance (Priority: P1) 🎯 MVP

**Goal**: User completes the day name and exercise blocks on step 2, taps Continue → day plan saved → all blocks saved → wizard advances to step 3.

**Independent Test**: Open step 2 with mock service, fill name + 1 block, tap Continue, verify wizard advances to the next step (step 3).

### Tests for US1

- [x] T010 Write failing UI test stub in `BodyMetricUITests/DayConfigUITests.swift` (register in BodyMetricUITests target): test P1 journey — wizard at step 2, enter day name in text field, tap Continue, verify wizard has advanced (e.g. a step-3 element appears); add `XCTSkipIf` for CI; stub `accessibilityIdentifier("newPlanWizard")` already on wizard

### Implementation for US1

- [x] T011 [US1] Update `Features/NewPlan/ViewModels/NewPlanViewModel.swift`: add `var workoutPlanIds: [DayOfWeek: Int] = [:]`; add `var isDayConfigSaving: Bool = false`; add `var dayConfigSaveError: String? = nil`; update `saveDays(using:onSuccess:)` — change `try await service.saveDays(requests)` to `let savedDays = try await service.saveDays(requests)` and add loop `for response in savedDays { if let day = DayOfWeek(rawValue: response.plannedWeekNumber) { workoutPlanIds[day] = response.planId } }`; add `func saveDayConfig(for day: DayOfWeek, using service: any WorkoutDayPlanServiceProtocol, onSuccess: @MainActor @Sendable () -> Void) async` — guard `!isDayConfigSaving`, sets `isDayConfigSaving = true`, `dayConfigSaveError = nil`, builds `WorkoutDayPlanRequest(name: plan.sessionName, orderIndex: day.rawValue - 1, isActive: true)`, calls `service.saveDayPlan(workoutPlanId: planId, request:)`, loops sequentially over `plan.blocks` calling `service.saveExerciseBlock(workoutDayPlanId: response.workoutDayPlanId, request: ExerciseBlockPlanRequest(block:))`, calls `onSuccess()` on full success, logs all trace events; run T004 — all tests must pass; depends on T009
- [x] T012 [US1] Update `Features/NewPlan/Views/NewPlanWizardView.swift`: add `let dayConfigService: any WorkoutDayPlanServiceProtocol` parameter; in `continueButton(enabled:isSaving:)`, for steps 2...totalSteps-1 (day configure steps), change the button action from `viewModel.advance()` to `Task { await viewModel.saveDayConfig(for: day, using: dayConfigService, onSuccess: { viewModel.advance() }) }`; pass `viewModel.currentDayOfWeek` as `day`; add `viewModel.isDayConfigSaving` as additional disabled condition on the Continue button when on a day-config step; show spinner in button label when `isDayConfigSaving`; pass `service` to `SelectDaysStepView` as before; depends on T011
- [x] T013 [US1] Update `Features/Workout/Views/TodayView.swift`: in `.fullScreenCover(isPresented: $showWizard)`, change `NewPlanWizardView(service: WorkoutPlanService(networkClient: networkClient))` to `NewPlanWizardView(service: WorkoutPlanService(networkClient: networkClient), dayConfigService: WorkoutDayPlanService(networkClient: networkClient))`; depends on T012

**Checkpoint**: US1 fully functional. Step 2 Continue → saves day → saves blocks → wizard advances.

---

## Phase 4: User Story 2 — Recover from a save failure on any part of the configuration (Priority: P2)

**Goal**: Any save failure keeps the user on step 2 with an error message and all entered data preserved.

**Independent Test**: Mock service throws on `saveDayPlan`, tap Continue with valid data, verify error banner shows and wizard stays on step 2.

### Tests for US2

- [x] T014 [P] [US2] Add test cases to `BodyMetricTests/Features/NewPlanViewModelTests.swift` (in `NewPlanViewModelDayConfigTests`): test that after `saveDayConfig` failure, `dayConfigSaveError` contains a non-empty user-facing string; test that `dayPlans[day]` is unchanged after failure (data preserved); test that calling `toggleDay` after failure clears `dayConfigSaveError`; test that rapid double-tap of Continue is blocked by `isDayConfigSaving` guard

### Implementation for US2

- [x] T015 [US2] Update `Features/NewPlan/Views/Components/ConfigureDayStepView.swift`: add inline error banner (same pattern as `SelectDaysStepView` error banner) shown when `viewModel.dayConfigSaveError != nil`; the banner uses `GrayscalePalette.surface` background + warning SF Symbol + `GrayscalePalette.primary` text; dismiss the error when the session name `TextField` changes (add `onChange` modifier that sets `viewModel.dayConfigSaveError = nil`); dismiss the error when an exercise block is added or removed; run T014 — tests must pass; depends on T011

**Checkpoint**: US1 AND US2 functional. Save failure shows error; user can edit and retry.

---

## Phase 5: User Story 3 — All exercise blocks saved in full before advancing (Priority: P3)

**Goal**: The wizard NEVER advances with partial data; if any block POST fails, the full step stays put.

**Independent Test**: Mock service lets day plan succeed, first block succeed, second block fail → wizard stays on step 2, error shown.

### Tests for US3

- [x] T016 [P] [US3] Add test case to `BodyMetricTests/Features/NewPlanViewModelTests.swift` (in `NewPlanViewModelDayConfigTests`): test with `MockWorkoutDayPlanService` where `saveDayPlan` succeeds (returns response), first `saveExerciseBlock` succeeds, second `saveExerciseBlock` throws — assert `onSuccess` NOT called, `dayConfigSaveError != nil`

### Implementation for US3

- [x] T017 [US3] Verify `NewPlanViewModel.saveDayConfig` loop is sequential — the `for block in plan.blocks { try await service.saveExerciseBlock(...) }` loop uses `try await` in sequence; no `TaskGroup`; on the first throw the loop exits and the catch sets the error; this is already implemented in T011 — confirm it, add a brief code comment explaining intentional sequential execution

**Checkpoint**: All three user stories independently functional and verified.

---

## Final Phase: Polish & Cross-Cutting Concerns

- [x] T018 [P] Verify all new Swift files (`WorkoutDayPlanModels.swift`, `WorkoutDayPlanServiceProtocol.swift`, `WorkoutDayPlanService.swift`, `WorkoutDayPlanServiceTests.swift`, `DayConfigUITests.swift`) are registered in the correct Xcode targets (check `.xcodeproj` group structure mirrors `Services/WorkoutPlan/` pattern from existing `WorkoutPlanService`); build to confirm no "file not found" errors
- [x] T019 [P] Audit trace events against quickstart.md: confirm `Logger.info("wizard_day_config_save_started")`, `Logger.info("wizard_day_plan_saved workoutDayPlanId:...")`, `Logger.info("wizard_exercise_blocks_saved count:...")`, `Logger.error("wizard_day_config_save_failed")` are all present in `NewPlanViewModel.saveDayConfig`
- [x] T020 [P] Audit Constitution VI compliance: `grep -n "Color(" Models/WorkoutDayPlanModels.swift Services/WorkoutPlan/WorkoutDayPlanService.swift Features/NewPlan/Views/Components/ConfigureDayStepView.swift` — confirm zero raw `Color(red:green:blue:)` values
- [x] T021 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1**: T001 — no dependencies; start immediately
- **Phase 2**: T002 + T003 + T004 (tests, parallel) → T005 + T006 (parallel) → T007 → T008 (parallel with T007) → T009
- **Phase 3 (US1)**: T010 (UI test, parallel) → T011 → T012 → T013
- **Phase 4 (US2)**: T014 (tests, parallel with T012/T013) → T015
- **Phase 5 (US3)**: T016 (parallel) → T017 (verify only)
- **Final**: T018 + T019 + T020 (parallel) → T021

### Within Phase 2

| Task | Depends on |
|------|-----------|
| T005 (DTOs) | T001 (file exists) |
| T006 (protocol update) | T005 (WorkoutPlanDayResponse type) |
| T007 (service update) | T005, T006 |
| T008 (new protocol) | T005 |
| T009 (new service) | T005, T008 |

### Within Phase 3

| Task | Depends on |
|------|-----------|
| T011 (ViewModel) | T009 (WorkoutDayPlanServiceProtocol must compile) |
| T012 (WizardView) | T011 |
| T013 (TodayView) | T012 |

---

## Parallel Opportunities

```
Phase 2 — write failing tests simultaneously:
  T002 (WorkoutDayPlanServiceTests) ‖ T003 (WorkoutPlanServiceTests) ‖ T004 (ViewModelTests)

Phase 2 — implement simultaneously:
  T005 (DTOs) ‖ T006 (protocol update)
  Then: T007 ‖ T008 (different files, share T005 dep)
  Then: T009 (needs T008)

Phase 3 + 4:
  T010 (UI test stub) ‖ T011 → T012 → T013
  T014 (US2 tests) starts after T011 exists

Phase 5:
  T016 ‖ T017 (parallel verification)

Final:
  T018 ‖ T019 ‖ T020 (all parallel) → T021
```

---

## Implementation Strategy

### MVP (User Story 1 only — 13 tasks)

1. Phase 1: T001
2. Phase 2: T002 + T003 + T004 → T005 + T006 → T007 → T008 → T009
3. Phase 3: T010 → T011 → T012 → T013
4. **STOP**: Verify — fill step 2, tap Continue, confirm wizard advances to step 3
5. Final: T021

### Full Delivery (all stories — 21 tasks)

MVP + Phase 4 (T014 + T015) + Phase 5 (T016 + T017) + Final (T018–T021).

---

## Notes

- `[P]` tasks touch different files — safe for parallel execution
- TDD mandatory: all Txx tests must FAIL before their corresponding implementation tasks
- `ExerciseBlockPlanRequest` field names (`targetWeightKg`, `restSeconds`) are assumed — verify against live API and update `CodingKeys` if needed
- `MockWorkoutDayPlanService` is defined in the test class (T004); it must be available to T014 and T016 test additions
- Commit convention: `✨ T011: add saveDayConfig to NewPlanViewModel`
