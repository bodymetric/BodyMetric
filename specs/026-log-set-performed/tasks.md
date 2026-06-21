# Tasks: Fix Begin Session Decode Failure (026 Bug Fix)

**Input**: Design documents from `/specs/026-log-set-performed/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ quickstart.md ✅ contracts/ ✅

**Scope**: 1 model change, 1 VM guard, 3 test fixture updates, 1 new test case. No new files. No new SPM packages.

---

## Phase 1: Setup

No new directories, packages, or project files required.

---

## Phase 2: Foundational — Fix the Decode Failure

**Purpose**: Make `exerciseBlockExecutionId` optional at the decode boundary so the session can start even when the backend omits the field. This unblocks all subsequent phases.

**⚠️ CRITICAL**: No user story work can begin until this task is complete.

- [X] T001 In `Models/WorkoutExecutionModels.swift`: change `let exerciseBlockExecutionId: Int` to `let exerciseBlockExecutionId: Int?` on `ExerciseBlockPlan` (line ~29); update `toWorkoutSession()` to pass `exerciseBlockExecutionId: block.exerciseBlockExecutionId ?? 0` to `WorkoutExercise(...)`.

**Checkpoint**: After T001, `xcodebuild build` must succeed with zero new errors. The session start call will no longer fail to decode when `exerciseBlockExecutionId` is absent from the response.

---

## Phase 3: User Story 1 — Session Starts Successfully (Priority: P1) 🎯

**Goal**: The app decodes the start-session response without crashing, regardless of whether `exerciseBlockExecutionId` is present in the JSON.

**Independent Test**: Open the app, tap "Begin session" with the current backend — confirm the active session screen opens with the exercise list displayed and no error banner. In tests, confirm `WorkoutExecutionService` decodes a JSON fixture that omits `exerciseBlockExecutionId` without throwing.

- [X] T002 [P] [US1] In `BodyMetricTests/Services/WorkoutExecutionServiceTests.swift`: remove the `"exerciseBlockExecutionId": 301` key-value pair from the `fixtureJSON` string (the JSON fixture must now reflect what the backend actually returns — no `exerciseBlockExecutionId` key). Confirm the existing decode test still passes.

- [X] T003 [P] [US1] In `BodyMetricTests/Features/ReadyToLiftViewModelTests.swift`: remove `exerciseBlockExecutionId: 301` from all `ExerciseBlockPlan(...)` constructor calls (both in `makeFixtureResponse()` and `test_fixtureResponse_toWorkoutSession_sortsByOrderIndex()`). Since `exerciseBlockExecutionId` is now `Int?`, omitting it will use Swift's synthesized memberwise init with `nil`. Confirm all tests in this file still pass.

**Checkpoint**: After T002 + T003, all existing tests pass. `xcodebuild test` for the affected test classes succeeds.

---

## Phase 4: User Story 2 — Guard Against Missing Execution ID at Log Time (Priority: P2)

**Goal**: When `exerciseBlockExecutionId` is 0 (because the backend omitted it), the "Log set" button shows a clear error instead of making a meaningless API call to `/api/exercise-block-executions/0/performed-sets`.

**Independent Test**: In `ActiveSessionViewModelTests`, pass `exerciseBlockExecutionId: 0` in the `WorkoutExercise` fixture, call `commitSet`, and confirm: `MockPerformedSetService.callCount == 0`, `logError != nil`, and `progress[0].sets[0].done == false`.

- [X] T004 [US2] In `Features/Workout/ViewModels/ActiveSessionViewModel.swift`: in `commitSet(exIdx:setIdx:weight:reps:)`, after the `reps > 0` validation and before the `isSubmittingLog` guard, add:
  ```swift
  let executionId = workout.exercises[exIdx].exerciseBlockExecutionId
  guard executionId > 0 else {
      Logger.error("ActiveSessionViewModel: commitSet called with executionId=0 — server did not return exerciseBlockExecutionId", category: .network)
      logError = "Cannot log set: session data is incomplete. Please end and restart the session."
      return
  }
  ```
  Remove the `let executionId = ...` line that currently appears later inside the function body (it is now declared above the guard). Pass `executionId` to `performedSetService.logPerformedSet(exerciseBlockExecutionId: executionId, ...)`.

- [X] T005 [P] [US2] In `BodyMetricTests/Features/ActiveSessionViewModelTests.swift`: add a new test method `test_commitSet_zeroExecutionId_setsLogErrorNoNetworkCall()`. Build the `WorkoutExercise` fixture with `exerciseBlockExecutionId: 0`. Call `await sut.commitSet(exIdx: 0, setIdx: 0, weight: 70.0, reps: 8)`. Assert: `mockService.callCount == 0`, `sut.logError != nil`, `sut.progress[0].sets[0].done == false`, `sut.isSubmittingLog == false`. Place this test alongside the existing zero-reps test for grouping clarity.

**Checkpoint**: After T004 + T005, the new test passes. The "Log set" button shows an error when `exerciseBlockExecutionId == 0`. Tapping the button with a valid ID proceeds normally.

---

## Phase 5: Build Verification

- [X] T006 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED. Depends on T001–T005.

---

## Dependencies

```
T001 [Foundational] (WorkoutExecutionModels — exerciseBlockExecutionId: Int → Int?)
    ↓
T002 [P] (WorkoutExecutionServiceTests — remove field from JSON fixture)    ← parallel
T003 [P] (ReadyToLiftViewModelTests — remove field from model fixture)      ← parallel
    ↓ (T001 done)
T004 (ActiveSessionViewModel — add guard executionId > 0)
T005 [P] (ActiveSessionViewModelTests — new zero-executionId test)          ← parallel with T004
    ↓
T006 (build verification)
```

T002 and T003 touch different test files and can run in parallel after T001.  
T004 and T005 touch different files and can run in parallel after T001.

---

## Notes

- T001 is the only change that affects how production code decodes API responses. Everything else is defensive guard and test hygiene.
- T004 adds the guard **before** `isSubmittingLog = true` so the guard path never leaves `isSubmittingLog` stuck as `true`.
- When the backend eventually adds `exerciseBlockExecutionId` to the start-session response: the `Int?` decode becomes non-nil, the `?? 0` mapping resolves to the real ID, and the T004 guard becomes unreachable — all without any further code change.
- T005 reuses the existing `MockPerformedSetService` from the same test file; no new mock needed.
