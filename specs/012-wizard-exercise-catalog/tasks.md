# Tasks: Wizard Step 2 — Live Exercise Catalog

**Input**: Design documents from `/specs/012-wizard-exercise-catalog/`  
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Tests**: Included — required by Constitution Principle II (TDD, ≥ 90% coverage). Write tests first; verify they FAIL before implementing.

**Organization**: Tasks grouped by user story for independent delivery.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1 / US2 / US3
- All new Swift files must be registered in `BodyMetric.xcodeproj`

---

## Phase 1: Setup

**Purpose**: Create `Services/Exercise/` directory and register placeholder files so subsequent tasks compile.

- [x] T001 Create directory `Services/Exercise/` and three placeholder files (`ExerciseServiceProtocol.swift`, `ExerciseService.swift` each containing only `import Foundation`); create placeholder `BodyMetricTests/Services/ExerciseServiceTests.swift` containing only `import XCTest`; register all four files in `BodyMetric.xcodeproj` — first three in BodyMetric target (under the `Services/WorkoutPlan/` group pattern), last one in BodyMetricTests target (under the test `Services/` group); also register `Models/ExerciseCatalogModels.swift` placeholder in BodyMetric target

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: DTOs, service protocol, concrete service, and the `ExerciseBlockPlanRequest.exerciseId` type change. All user stories depend on these compiling.

**⚠️ CRITICAL**: Do not start story phases until T002–T007 are complete and the build succeeds.

### Tests (write first — must FAIL before T005–T006)

- [x] T002 [P] Write failing unit tests in `BodyMetricTests/Services/ExerciseServiceTests.swift` using `MockNetworkClient`: `test_fetchExerciseCatalog_200_returnsDecodedGroups` — mock JSON `[{"group":"back","exercises":[{"id":26,"name":"Back Extension"}]}]`, status 200, assert result has 1 group with 1 exercise with id=26 and name="Back Extension"; `test_fetchExerciseCatalog_500_throwsServerError` — status 500, assert `WorkoutPlanError.serverError(500)`; `test_fetchExerciseCatalog_networkError_throws` — `mockClient.errorToThrow = URLError(.notConnectedToInternet)`, assert throws

- [x] T003 [P] Add failing tests to `BodyMetricTests/Features/NewPlanViewModelTests.swift` in a new `ExerciseCatalogTests` class: `test_loadExerciseCatalog_success_setsLoadedState` — mock service returns one group, call `loadExerciseCatalog`, assert `exerciseCatalogLoadState == .loaded` and `exerciseGroups.count == 1`; `test_loadExerciseCatalog_failure_setsFailedState` — mock service throws, assert `exerciseCatalogLoadState == .failed(...)`; `test_loadExerciseCatalog_calledTwice_fetchesOnce` — call `loadExerciseCatalog` twice, verify mock service `fetchCount == 1` (single-load guard); define `MockExerciseService` conforming to `ExerciseServiceProtocol`

### Implementation

- [x] T004 [P] Create `Models/ExerciseCatalogModels.swift`: define `struct ApiExercise: Decodable, Identifiable { let id: Int; let name: String }`; define `struct ExerciseCatalogGroup: Decodable, Identifiable { let group: String; let exercises: [ApiExercise]; var id: String { group } }`; define `enum ExerciseCatalogLoadState: Equatable { case idle, loading, loaded, failed(String) }`; register in BodyMetric target; depends on T001

- [x] T005 [P] Populate `Services/Exercise/ExerciseServiceProtocol.swift`: define `@MainActor protocol ExerciseServiceProtocol: AnyObject { func fetchExerciseCatalog() async throws -> [ExerciseCatalogGroup] }`; depends on T004

- [x] T006 Populate `Services/Exercise/ExerciseService.swift`: `@MainActor final class ExerciseService: ExerciseServiceProtocol`; `private static let baseURL = "https://api.bodymetric.com.br/api/exercises"`; `init(networkClient: any NetworkClientProtocol)`; `fetchExerciseCatalog()` builds GET URLRequest, calls `networkClient.data(for:)`, handles 200 → `JSONDecoder().decode([ExerciseCatalogGroup].self, from: data)`, non-200 → throw `WorkoutPlanError.serverError(statusCode)`, network error → throw `WorkoutPlanError.networkError(error)`; `Logger.error` at all catch sites; run T002 — all tests must pass; depends on T004, T005

- [x] T007 [P] Update `Models/WorkoutDayPlanModels.swift`: change `ExerciseBlockPlanRequest.exerciseId` from `let exerciseId: String` to `let exerciseId: Int`; update `init(block: ExerciseBlock)` to `self.exerciseId = Int(block.exerciseId) ?? 0`; update `CodingKeys` mapping if present (the JSON key stays `"exerciseId"`)

**Checkpoint**: Foundation builds. T002 and T003 pass. Story phases can begin.

---

## Phase 3: User Story 1 — See real exercises in the exercise picker (Priority: P1) 🎯 MVP

**Goal**: When the user opens an exercise picker on step 2, real exercises from the server appear grouped by muscle group (e.g., "back" → "Back Extension", "Barbell Row").

**Independent Test**: Open step 2 with a mock service returning one group with two exercises, open the exercise picker, verify both exercises appear under the correct group heading.

### Implementation for US1

- [x] T008 [US1] Update `Features/NewPlan/ViewModels/NewPlanViewModel.swift`: add `var exerciseGroups: [ExerciseCatalogGroup] = []`; add `var exerciseCatalogLoadState: ExerciseCatalogLoadState = .idle`; add `func loadExerciseCatalog(using service: any ExerciseServiceProtocol) async` — guard `exerciseGroups.isEmpty` for single-load; sets `.loading`; traces `exercise_catalog_load_started`; on success sets `exerciseGroups` and `.loaded`, traces `exercise_catalog_load_success groupCount:\(...)`; on error sets `.failed(message)`, traces `exercise_catalog_load_failed`; add `func reloadExerciseCatalog(using service: any ExerciseServiceProtocol) async` — clears `exerciseGroups = []` then calls `loadExerciseCatalog`; add `func exerciseName(for exerciseId: String) -> String?` — `guard let id = Int(exerciseId) else { return nil }; return exerciseGroups.flatMap(\.exercises).first { $0.id == id }?.name`; run T003 — all tests must pass; depends on T004, T006

- [x] T009 [P] [US1] Update `Features/NewPlan/Views/Components/ExercisePickerSheetView.swift`: add `let exerciseCatalog: [ExerciseCatalogGroup]` parameter; replace the `private var filteredGroups` computed var — filter `exerciseCatalog` by `query` (check `exercise.name` and `group.group` case-insensitively); update `muscleSection` to accept `ExerciseCatalogGroup` instead of `MuscleGroup`; update exercise row Button action to call `onPick(String(ex.id)); dismiss()`; remove the `private struct MuscleGroup` (now using `ExerciseCatalogGroup` directly); depends on T004

- [x] T010 [P] [US1] Update `Features/NewPlan/Views/Components/ExerciseBlockRowView.swift`: add `exerciseName: String?` parameter to the struct; remove the private `selectedExercise: Exercise?` computed var and `exerciseName: String?` computed var; use the injected `exerciseName` parameter directly in `exercisePickerTrigger` label (both for the display name and the nil check); update `muscleLabel` to use the parent-supplied name or "PICK AN EXERCISE"

- [x] T011 [US1] Update `Features/NewPlan/Views/Components/ConfigureDayStepView.swift`: add `let exerciseService: any ExerciseServiceProtocol` parameter; add `.task { await viewModel.loadExerciseCatalog(using: exerciseService) }` to the root `VStack`; in the `ExerciseBlockRowView` call inside `blockSection`, pass `exerciseName: viewModel.exerciseName(for: block.exerciseId)`; in the `ExercisePickerSheetView` sheet, pass `exerciseCatalog: viewModel.exerciseGroups`; add `ExercisePickerSheetView(exerciseCatalog: viewModel.exerciseGroups, currentExerciseId: ..., onPick: ...)`; depends on T008, T009, T010

- [x] T012 [US1] Update `Features/NewPlan/Views/NewPlanWizardView.swift`: add `let exerciseService: any ExerciseServiceProtocol` parameter; in `stepBody`, pass `exerciseService: exerciseService` to `ConfigureDayStepView`; depends on T011

- [x] T013 [US1] Update `Features/Workout/Views/TodayView.swift`: in `.fullScreenCover(isPresented: $showWizard)`, add `exerciseService: ExerciseService(networkClient: networkClient)` to the `NewPlanWizardView(...)` call; depends on T012

**Checkpoint**: US1 fully functional. Open step 2, tap exercise picker — real API exercises appear grouped by muscle.

---

## Phase 4: User Story 2 — Exercise list loads once and is shared (Priority: P2)

**Goal**: All exercise pickers on the screen share one loaded catalog; no additional fetches when blocks are added.

**Independent Test**: Add three exercise blocks, verify exactly one service call was made.

### Tests for US2

- [x] T014 [P] [US2] Verify in `BodyMetricTests/Features/NewPlanViewModelTests.swift` that `test_loadExerciseCatalog_calledTwice_fetchesOnce` (written in T003) correctly asserts `fetchCount == 1` after two calls; also add `test_addingBlock_doesNotTriggerCatalogReload` — call `loadExerciseCatalog` once (success), then call `addBlock(for:)`, verify `fetchCount` is still 1

**Checkpoint**: Single-load constraint verified. US1 AND US2 functional.

---

## Phase 5: User Story 3 — Graceful handling when exercise list cannot be loaded (Priority: P3)

**Goal**: Network/server failure shows a user-friendly error banner with a retry button instead of a silent empty picker.

**Independent Test**: Configure mock service to throw, open step 2, verify error banner appears with retry option.

### Implementation for US3

- [x] T015 [US3] Update `Features/NewPlan/Views/Components/ConfigureDayStepView.swift`: add a `exerciseCatalogErrorBanner` view shown when `viewModel.exerciseCatalogLoadState == .failed` — GrayscalePalette.surface background + warning SF Symbol + error message text + "Retry" button that calls `Task { await viewModel.reloadExerciseCatalog(using: exerciseService) }`; show the banner above the `sessionNameField` section; add a loading skeleton or `ProgressView` shown when `exerciseCatalogLoadState == .loading` inside the exercise blocks area; depends on T008

**Checkpoint**: All three user stories functional. Step 2 handles loaded, loading, and failed states.

---

## Final Phase: Polish & Cross-Cutting Concerns

- [x] T016 [P] Verify all new Swift files are correctly registered in `BodyMetric.xcodeproj` (run `xcodebuild build` to confirm no "file not found" errors); if any new file was not registered via T001, add it using the Python pbxproj script pattern from previous features
- [x] T017 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED with no new errors

---

## Dependencies & Execution Order

```
T001 (setup)
    ↓
T002 [P] + T003 [P] (failing tests)  +  T004 [P] + T005 [P] + T007 [P] (parallel)
    ↓
T006 (ExerciseService — needs T004, T005; run T002)
    ↓
T008 [US1] (ViewModel — needs T004, T006; run T003)
T009 [P] [US1] (PickerSheet — needs T004)   ← parallel with T008
T010 [P] [US1] (BlockRow — independent)     ← parallel with T008
    ↓
T011 [US1] (ConfigureDayStep — needs T008 + T009 + T010)
    ↓
T012 [US1] (WizardView — needs T011)
    ↓
T013 [US1] (TodayView — needs T012)
    ↓
T014 [US2] + T015 [US3] (parallel verifications)
    ↓
T016 [P] + T017 (build)
```

---

## Parallel Opportunities

```
Phase 2:
  T002 + T003 (tests, parallel)
  T004 + T005 + T007 (parallel — different files)
  T006 (sequential — needs T004 + T005)

Phase 3 (after T006 + T007 compile):
  T008 + T009 + T010 (parallel — different files)
  T011 → T012 → T013 (sequential chain)
  
Phase 4 + 5:
  T014 + T015 (parallel after T008/T011 exist)
```

---

## Implementation Strategy

### MVP (US1 only — 13 tasks)

1. Phase 1: T001
2. Phase 2: T002 → T004 + T005 → T006 → T007
3. Phase 3: T008 + T009 + T010 → T011 → T012 → T013
4. **STOP**: Open step 2, verify real exercises in pickers
5. Final: T016 + T017

### Full Delivery (all stories — 17 tasks)

Same as MVP + T003 (failing test added earlier) + T014 (US2 test) + T015 (US3 error banner).

---

## Notes

- `ExerciseBlock.exerciseId` stays `String` (stores "26") — backward-compatible with stored plans
- `ExerciseBlockPlanRequest.exerciseId` changes to `Int` (T007) — server expects integer
- The static `Exercise.catalog` in `NewPlanModels.swift` is no longer used by the picker; it can remain (for backward compat with any existing tests) but is effectively dead code
- `MockExerciseService` is defined in `NewPlanViewModelTests.swift` (T003); reuse it in T014
- Commit convention: `✨ T008: add exerciseCatalog loading to NewPlanViewModel`
