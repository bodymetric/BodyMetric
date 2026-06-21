# Tasks: Start Session Returns Exercise Block Execution ID

**Input**: Design documents from `/specs/027-start-session-execution-id/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ quickstart.md ✅ contracts/ ✅

**Scope**: 2 production files modified, 3 test files modified, 1 new test added. No new files. No new SPM packages.

---

## Phase 1: Setup

No new directories, packages, or project files required.

---

## Phase 2: Foundational — Make `exerciseBlockExecutionId` Required

**Purpose**: Change `ExerciseBlockPlan.exerciseBlockExecutionId` from `Int?` back to `Int`. This is the single blocking prerequisite — all other tasks depend on it because it changes the type of a widely-used field.

**⚠️ CRITICAL**: No user story work can begin until this task is complete. A build failure here means dependent fixture tasks won't compile.

- [X] T001 In `Models/WorkoutExecutionModels.swift`: change `let exerciseBlockExecutionId: Int?` to `let exerciseBlockExecutionId: Int` on `ExerciseBlockPlan`; update `toWorkoutSession()` to pass `exerciseBlockExecutionId: block.exerciseBlockExecutionId` (remove the `?? 0` — it won't compile on a non-optional anyway).

**Checkpoint**: After T001, `xcodebuild build` must succeed. The field is now required; any JSON response missing it will throw `DecodingError.keyNotFound`, which is the desired behaviour per US3.

---

## Phase 3: User Stories 1 & 2 — Session Starts with Valid IDs, Log Set Uses Correct ID (Priority: P1) 🎯

**Goal**: The app decodes the start-session response with `exerciseBlockExecutionId` present and required. Each block carries its correct ID in memory. "Log set" submits the right ID. Test fixtures reflect this.

**Independent Test**: Start a session with a JSON response that includes `exerciseBlockExecutionId`; confirm each `WorkoutExercise` in memory has the correct non-zero ID; tap "Log set" on each block and confirm the service receives the matching ID.

- [X] T002 [P] [US1] In `BodyMetricTests/Services/WorkoutExecutionServiceTests.swift`: restore `"exerciseBlockExecutionId": 301` in the `fixtureJSON` string, inside the `exerciseBlockPlans[0]` object (after `"exerciseBlockPlanId": 72`). Confirm existing decode tests still pass.

- [X] T003 [P] [US1] In `BodyMetricTests/Features/ReadyToLiftViewModelTests.swift`: change `exerciseBlockExecutionId: nil` back to `exerciseBlockExecutionId: 301` in all `ExerciseBlockPlan(...)` constructor calls (both in `makeFixtureResponse()` and `test_fixtureResponse_toWorkoutSession_sortsByOrderIndex()`). Confirm all tests in this file still pass.

- [X] T004 [P] [US2] In `BodyMetricTests/Features/ActiveSessionViewModelTests.swift`: in `makeFixtureSession()`, change `exerciseBlockExecutionId: 0` to `exerciseBlockExecutionId: 301` (or any positive non-zero Int) so the fixture reflects a real server-provided ID. Confirm all existing tests pass. The `test_commitSet_zeroExecutionId_setsLogErrorNoNetworkCall` test must also still pass — it constructs its own session with `exerciseBlockExecutionId: 0` directly.

**Checkpoint**: After T002 + T003 + T004, all existing tests pass. Session start decodes correctly; the in-memory model carries the real ID; "Log set" routes to the correct API path.

---

## Phase 4: User Story 3 — Graceful Failure When Execution ID Is Missing (Priority: P2)

**Goal**: Prove at the test level that omitting `exerciseBlockExecutionId` from the server response causes a decode failure (not a silent nil), so the check-in screen error banner is shown and the user is never taken into a broken session.

**Independent Test**: Pass a JSON fixture without `exerciseBlockExecutionId` to `WorkoutExecutionService.startSession`; confirm it throws (not returns nil or a zero-ID object).

- [X] T005 [US3] In `BodyMetricTests/Services/WorkoutExecutionServiceTests.swift`: add a new test method `test_startSession_missingExecutionId_throwsDecodingError()`. Construct a `fixtureJSON` string identical to the existing fixture but without the `"exerciseBlockExecutionId"` key. Call `try await sut.startSession(...)` with that fixture and assert it throws. Use `XCTAssertThrowsError` or `await XCTAssertThrowsErrorAsync`. The thrown error should be `WorkoutPlanError.decodingError`.

**Checkpoint**: After T005, the new test passes and the US3 decode-failure contract is locked in at the service layer.

---

## Phase 5: Build Verification

- [X] T006 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED. Depends on T001–T005.

---

## Dependencies

```
T001 [Foundational] (WorkoutExecutionModels — Int? → Int, remove ?? 0)
    ↓
T002 [P] [US1] (WorkoutExecutionServiceTests — restore JSON fixture field)   ← parallel
T003 [P] [US1] (ReadyToLiftViewModelTests — restore model fixture field)     ← parallel
T004 [P] [US2] (ActiveSessionViewModelTests — restore fixture to real ID)    ← parallel
T005      [US3] (WorkoutExecutionServiceTests — add missing-field decode test)
    ↓
T006 (build verification)
```

T002, T003, T004 all touch different files and can run in parallel after T001.  
T005 touches the same file as T002 — run sequentially after T002 completes, or apply both edits to `WorkoutExecutionServiceTests.swift` in a single pass.

---

## Notes

- T001 is the only change to production model code. Everything else is test hygiene and a new test.
- T004: The existing `test_commitSet_zeroExecutionId_setsLogErrorNoNetworkCall` test remains valid and must keep passing. It creates its own local `WorkoutSession` with `exerciseBlockExecutionId: 0` directly — this tests the `guard executionId > 0` path in `commitSet` for the case where the server sends an invalid 0 value.
- T005: `WorkoutExecutionService` wraps `DecodingError` in `WorkoutPlanError.decodingError` before throwing. The new test asserts that error type specifically, not the raw `DecodingError`.
- After this feature: `exerciseBlockExecutionId` is required end-to-end. The `?? 0` fallback is gone. The `guard executionId > 0` in `commitSet` is kept as a final defence against a server sending 0 (which is semantically invalid but would otherwise decode successfully).
