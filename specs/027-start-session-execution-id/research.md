# Research: Start Session Returns Exercise Block Execution ID

**Feature**: `027-start-session-execution-id`  
**Date**: 2026-06-21  
**Status**: Complete — all decisions resolved

---

## Decision 1: Make `exerciseBlockExecutionId` a required field (`Int`) in `ExerciseBlockPlan`

**Decision**: Change `ExerciseBlockPlan.exerciseBlockExecutionId` from `Int?` back to `Int`.

**Rationale**: The field was made optional in the 026 bug fix because the server was not returning it. Now that the server always returns it, making it required aligns the model with the contract and removes the need for defensive `?? 0` mapping. A non-optional `Int` means decoding fails immediately if the field is absent, which is exactly the desired behavior per FR-006 and US3 — the decode error propagates up to `ReadyToLiftViewModel.beginSession`, which sets `loadState = .failed(...)` and shows the error banner on the check-in screen.

**Alternatives considered**:
- *Keep `Int?` and validate at the session model boundary*: Adds complexity — need to check all exercise blocks for nil after decoding and surface an error. More code for no benefit over letting `JSONDecoder` handle it.
- *Keep `Int?` permanently as defensive design*: The defensive guard in `commitSet` already exists. Keeping optionality in the decode layer adds unnecessary complexity now that the contract is defined.

---

## Decision 2: Remove the `?? 0` fallback in `toWorkoutSession()`

**Decision**: Change `block.exerciseBlockExecutionId ?? 0` to `block.exerciseBlockExecutionId` in `toWorkoutSession()`.

**Rationale**: With `exerciseBlockExecutionId: Int` (non-optional), the `?? 0` no longer compiles — it would be a compiler warning ("left side of ?? is never nil"). Remove it. `WorkoutExercise.exerciseBlockExecutionId` remains a non-optional `Int`, so the mapping is direct.

**Alternatives considered**: None — the `?? 0` is only needed when the source is `Int?`.

---

## Decision 3: Keep `guard executionId > 0` in `commitSet` as a final defense

**Decision**: Retain the `guard executionId > 0` guard in `ActiveSessionViewModel.commitSet`.

**Rationale**: The spec assumption states "the value 0 is treated as absent/invalid." If the server ever sends `exerciseBlockExecutionId: 0` (a valid JSON integer but semantically meaningless), the guard prevents a call to `POST /api/exercise-block-executions/0/performed-sets`. This is cheap defense with no UX cost. The guard message is updated to reflect the new context: it's now about an invalid server-sent value rather than a missing field.

**Alternatives considered**:
- *Remove the guard entirely*: Simpler code, but a server bug (sending 0) would silently make a bad API call. Keeping the guard is low cost.

---

## Decision 4: Add a decode-failure test for missing `exerciseBlockExecutionId` (US3 verification)

**Decision**: Add `test_startSession_missingExecutionId_throwsDecodingError` to `WorkoutExecutionServiceTests`.

**Rationale**: US3 requires the app to handle a missing `exerciseBlockExecutionId` as an error. The existing test infrastructure verifies the happy path. A new test with a JSON fixture that omits `exerciseBlockExecutionId` confirms the decode failure is thrown (not swallowed), which is the behavior that causes the check-in screen to show the error banner. This locks in the US3 contract at the service layer.

**Alternatives considered**:
- *Test at the ViewModel layer instead*: Could test `ReadyToLiftViewModel` with a service that throws `decodingError`. Equally valid, but testing at the service layer is more targeted and doesn't require mocking the network client for a decode test.

---

## Decision 5: Update test fixtures across three test files

**Decision**: Restore `"exerciseBlockExecutionId": 301` in JSON fixtures (`WorkoutExecutionServiceTests`) and `exerciseBlockExecutionId: 301` in Swift model fixtures (`ReadyToLiftViewModelTests`, `ActiveSessionViewModelTests`).

**Rationale**: Fixtures were set to omit/nil the field in the bug fix. Now that the field is required, any fixture that omits it will fail to compile (`ExerciseBlockPlan` init requires all non-optional fields) or fail to decode. Restoring the field makes fixtures reflect real server behavior.
