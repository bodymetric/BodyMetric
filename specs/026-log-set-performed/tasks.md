# Tasks: Log Set Performed

**Input**: Design documents from `/specs/026-log-set-performed/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ quickstart.md ✅ contracts/ ✅

**Scope**: 5 new files, 9 files modified. No new SPM packages. No new directories.

---

## Phase 1: Setup

No new directories, packages, or project files required.

---

## Phase 2: Foundational — Extend Models and Fix Fixtures

These tasks must complete first because every subsequent file depends on the new `exerciseBlockExecutionId` field.

- [X] T001 [P] In `Models/WorkoutExecutionModels.swift`: add `let exerciseBlockExecutionId: Int` to `ExerciseBlockPlan` (after `exerciseBlockPlanId`); update `toWorkoutSession()` to pass `exerciseBlockExecutionId: block.exerciseBlockExecutionId` to `WorkoutExercise(...)`.

- [X] T002 [P] In `Features/Workout/Models/WorkoutModels.swift`: add `let exerciseBlockExecutionId: Int` to `WorkoutExercise` (after `exerciseBlockPlanId`); update all 5 `WorkoutExercise(...)` calls in `mockToday` to include `exerciseBlockExecutionId: 0`.

- [X] T003 [P] Create `Models/PerformedSetModels.swift` with a single struct: `struct LogPerformedSetRequest: Encodable { let weight: Double; let reps: Int }`. Add file header comment following the project's comment style (see `WorkoutExecutionModels.swift` for reference).

- [X] T004 [P] In `BodyMetricTests/Features/ReadyToLiftViewModelTests.swift`: add `exerciseBlockExecutionId: 301` to both `ExerciseBlockPlan(...)` calls inside `makeFixtureResponse()` and `test_fixtureResponse_toWorkoutSession_sortsByOrderIndex()`. Also add `exerciseBlockExecutionId: 301` (or matching value) wherever `ExerciseBlockPlan(...)` is constructed.

- [X] T005 [P] In `BodyMetricTests/Services/WorkoutExecutionServiceTests.swift`: add `"exerciseBlockExecutionId": 301` to the JSON fixture string `fixtureJSON` inside the `exerciseBlockPlans[0]` object (alongside `"exerciseBlockPlanId": 72`).

**Checkpoint**: Build compiles with `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'`; all existing tests pass; `ExerciseBlockPlan` and `WorkoutExercise` both carry the new field.

---

## Phase 3: User Story 1 — Log a Performed Set (Priority: P1) 🎯

**Goal**: After the user enters weight + reps and taps "Log set," the app calls `POST /api/exercise-block-executions/{exerciseBlockExecutionId}/performed-sets`. On success the set row marks done and the rest timer starts. On failure the button re-enables and an error message is shown in the sheet.

**Independent Test**: Provide a `MockPerformedSetService`; confirm `ActiveSessionViewModel.commitSet` sends the correct `exerciseBlockExecutionId` from `WorkoutExercise`, marks the set done on success, and sets `logError` on failure.

- [X] T006 [US1] Create `Services/WorkoutExecution/PerformedSetServiceProtocol.swift`:
  ```swift
  protocol PerformedSetServiceProtocol {
      func logPerformedSet(exerciseBlockExecutionId: Int, weight: Double, reps: Int) async throws
  }
  ```
  Follow the same file header/comment style as `WorkoutExecutionServiceProtocol.swift`.

- [X] T007 [P] [US1] Create `Services/WorkoutExecution/PerformedSetService.swift`: implement `@MainActor final class PerformedSetService: PerformedSetServiceProtocol` that sends `POST https://api.bodymetric.com.br/api/exercise-block-executions/{exerciseBlockExecutionId}/performed-sets` with a JSON body of `LogPerformedSetRequest(weight:reps:)`. Accept 200 or 201; throw `WorkoutPlanError.serverError(code)` for any other status; throw `WorkoutPlanError.networkError(error)` on network failure; throw `WorkoutPlanError.decodingError` on encode failure (rare). Log with `Logger.info` on start and HTTP status; `Logger.error` on failure — no weight or reps in log messages (Constitution Principle III). Inject `NetworkClientProtocol` in init (same pattern as `WorkoutExecutionService`).

- [X] T008 [P] [US1] In `Features/Workout/ViewModels/ActiveSessionViewModel.swift`: (a) add `private let performedSetService: any PerformedSetServiceProtocol`; (b) update `init` to `init(workExecutionId: Int, workout: WorkoutSession, mood: String, performedSetService: any PerformedSetServiceProtocol)`; (c) add `private(set) var isSubmittingLog: Bool = false` and `private(set) var logError: String? = nil`; (d) make `commitSet(exIdx:setIdx:weight:reps:)` async — validate `reps > 0` (set `logError = "Reps must be at least 1"` and return early if not); guard against re-entry with `guard !isSubmittingLog else { return }`; set `isSubmittingLog = true, logError = nil`; call `try await performedSetService.logPerformedSet(exerciseBlockExecutionId: workout.exercises[exIdx].exerciseBlockExecutionId, weight: weight, reps: reps)`; on success update progress and close sheet as before + start rest timer; on error set `logError = "Failed to log set. Please try again."` and set `isSubmittingLog = false` without marking done or closing sheet.

- [X] T009 [P] [US1] In `Features/Workout/Views/Components/LogSetSheet.swift`: add two new parameters: `isLoading: Bool` and `error: String?` (both after `onCommit`). Disable the "Log set" button when `isLoading` is true. When `isLoading` is true, replace the button's `HStack` content with `ProgressView().tint(WorkoutPalette.onAccent)`. Add an error label above the "Log set" button that shows `error` text when non-nil using `.font(.system(size: 12, design: .monospaced)).foregroundStyle(GrayscalePalette.secondary)`. Update the existing `LogSetSheet` `init` to include the new parameters.

- [X] T010 [US1] In `Features/Workout/Views/ActiveSessionView.swift`: update the `LogSetSheet(...)` call inside the `if let target = viewModel.logTarget` block to pass `isLoading: viewModel.isSubmittingLog, error: viewModel.logError`; change the `onCommit` closure from a synchronous call to `Task { await viewModel.commitSet(exIdx: target.exIdx, setIdx: target.setIdx, weight: $0, reps: $1) }`.

- [X] T011 [US1] In `Features/Workout/Views/CheckInView.swift`: add `let performedSetService: any PerformedSetServiceProtocol` property (after `let service`); update the `navigationDestination(for: StartWorkoutResponse.self)` closure to pass `performedSetService: performedSetService` to `ActiveSessionViewModel(...)`.

- [X] T012 [US1] In `Features/Workout/Views/TodayView.swift`: update the `CheckInView(...)` call inside `.fullScreenCover(isPresented: $showCheckIn)` to pass `performedSetService: PerformedSetService(networkClient: networkClient)`.

**Checkpoint**: Build compiles; opening the active session screen and tapping "Log set" fires `POST /api/exercise-block-executions/{id}/performed-sets`; set row shows checkmark on success; button re-enables with error text on failure.

---

## Phase 4: User Story 2 — Error Handling Tests (Priority: P2)

**Goal**: Unit tests verify all error paths and the duplicate-submission guard so production behavior is locked in.

**Independent Test**: All tests in `PerformedSetServiceTests` and `ActiveSessionViewModelTests` pass.

- [X] T013 [P] [US2] Create `BodyMetricTests/Services/PerformedSetServiceTests.swift`: add `@MainActor final class PerformedSetServiceTests: XCTestCase` with `MockNetworkClient`. Tests:
  - `test_logPerformedSet_200_doesNotThrow` — mock 200, confirm no throw
  - `test_logPerformedSet_201_doesNotThrow` — mock 201, confirm no throw
  - `test_logPerformedSet_400_throwsServerError` — mock 400, confirm `WorkoutPlanError.serverError(400)`
  - `test_logPerformedSet_500_throwsServerError` — mock 500, confirm `WorkoutPlanError.serverError(500)`
  - `test_logPerformedSet_networkError_throwsNetworkError` — mock URLError, confirm `WorkoutPlanError.networkError`
  - `test_logPerformedSet_sendsPOSTToCorrectURL` — confirm `httpMethod == "POST"` and URL contains `/exercise-block-executions/123/performed-sets`
  - `test_logPerformedSet_requestBodyContainsWeightAndReps` — decode `LogPerformedSetRequest` from body; confirm `weight == 70.0, reps == 8`

- [X] T014 [P] [US2] Create `BodyMetricTests/Features/ActiveSessionViewModelTests.swift`: add `@MainActor final class ActiveSessionViewModelTests: XCTestCase` with `MockPerformedSetService`. Tests:
  - `test_commitSet_success_marksDoneAndClosesSheet` — mock success; confirm `progress[0].sets[0].done == true` and `logTarget == nil`
  - `test_commitSet_success_isSubmittingLogFalseAfter` — confirm `isSubmittingLog == false` after success
  - `test_commitSet_networkError_setsLogError` — mock `WorkoutPlanError.networkError`; confirm `logError != nil` and `isSubmittingLog == false`
  - `test_commitSet_serverError_setsLogError` — mock `WorkoutPlanError.serverError(500)`; confirm `logError != nil`
  - `test_commitSet_failure_setNotMarkedDone` — mock error; confirm `progress[0].sets[0].done == false`
  - `test_commitSet_reentryGuard_preventsDuplicateRequest` — set `isSubmittingLog = true` manually; call `commitSet`; confirm `callCount == 0`
  - `test_commitSet_zeroReps_setsLogErrorNoNetworkCall` — pass `reps: 0`; confirm `callCount == 0` and `logError != nil`
  - `test_commitSet_usesCorrectExerciseBlockExecutionId` — confirm `lastCall?.exerciseBlockExecutionId == workout.exercises[0].exerciseBlockExecutionId`

  Add `MockPerformedSetService` at bottom of file:
  ```swift
  @MainActor
  final class MockPerformedSetService: PerformedSetServiceProtocol {
      var errorToThrow: Error?
      var callCount = 0
      var lastCall: (exerciseBlockExecutionId: Int, weight: Double, reps: Int)?

      func logPerformedSet(exerciseBlockExecutionId: Int, weight: Double, reps: Int) async throws {
          callCount += 1
          lastCall = (exerciseBlockExecutionId, weight, reps)
          if let error = errorToThrow { throw error }
      }
  }
  ```

**Checkpoint**: All existing tests still pass; all new tests pass.

---

## Phase 5: Build Verification

- [X] T015 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED; depends on T001–T014.

---

## Dependencies

```
T001 [P] (WorkoutExecutionModels — exerciseBlockExecutionId in ExerciseBlockPlan + toWorkoutSession)
T002 [P] (WorkoutModels — exerciseBlockExecutionId in WorkoutExercise)         ← parallel with T001
T003 [P] (PerformedSetModels — LogPerformedSetRequest)                          ← parallel with T001/T002
    ↓ (T001–T003 done)
T004 [P] (ReadyToLiftViewModelTests — fixture update)
T005 [P] (WorkoutExecutionServiceTests — JSON fixture update)                   ← parallel with T004
    ↓ (T004–T005 done; build compiles cleanly)
T006 (PerformedSetServiceProtocol — new file)
    ↓
T007 [P] (PerformedSetService — implementation)
T008 [P] (ActiveSessionViewModel — async commitSet + service injection)          ← parallel with T007
T009 [P] (LogSetSheet — isLoading + error params)                                ← parallel with T007/T008
    ↓ (T008 + T009 done)
T010 (ActiveSessionView — wires VM state into LogSetSheet)
    ↓ (T008 done)
T011 (CheckInView — performedSetService param)
    ↓
T012 (TodayView — passes PerformedSetService to CheckInView)
    ↓ (all T006–T012 done)
T013 [P] (PerformedSetServiceTests — new test file)
T014 [P] (ActiveSessionViewModelTests — new test file)                           ← parallel with T013
    ↓
T015 (build verification)
```

T007, T008, T009 all touch different files and can be applied simultaneously after T006.
T013 and T014 touch different test files and can be applied simultaneously.

---

## Notes

- T001: `toWorkoutSession()` maps `block.exerciseBlockExecutionId` → `WorkoutExercise(exerciseBlockExecutionId:...)`. All 5 blocks in `mockToday` use `exerciseBlockExecutionId: 0` as placeholder.
- T003: `LogPerformedSetRequest` is a pure `Encodable` value type. No `Decodable` conformance needed.
- T007: The URL is `https://api.bodymetric.com.br/api/exercise-block-executions/\(exerciseBlockExecutionId)/performed-sets`. No response body is decoded.
- T008: The `isSubmittingLog` guard is `guard !isSubmittingLog else { return }` checked before setting `isSubmittingLog = true`, not inside a `do/catch`. The rest of `commitSet` (rest timer, auto-advance) runs only on success path.
- T009: The existing `LogSetSheet` `init` stores parameters in the same order; add `isLoading` and `error` after `onCommit`. Default values are NOT added — callers must supply them explicitly.
- T010: `onCommit` in `ActiveSessionView` was previously synchronous `{ weight, reps in viewModel.commitSet(...) }`. Replace the body with `Task { await viewModel.commitSet(exIdx: target.exIdx, setIdx: target.setIdx, weight: weight, reps: reps) }`.
- T013: Use `MockNetworkClient` (already present in test target). Call `logPerformedSet(exerciseBlockExecutionId: 123, weight: 70.0, reps: 8)` in each test.
- T014: Build a `WorkoutSession` fixture with `exerciseBlockExecutionId: 301`. Use `MockPerformedSetService`.
