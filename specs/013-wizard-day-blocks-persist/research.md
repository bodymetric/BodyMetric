# Research: Wizard Step 2 — Persist Day Plan with Exercise Blocks

**Date**: 2026-05-02

---

## 1. Unified POST replaces two-step save

**Decision**: Replace the feature-011 two-step save (POST /days then N × POST /exercise-blocks) with one POST /days that embeds `exerciseBlocks` in the body.

**Rationale**: The new API contract embeds exercise blocks directly in the day plan payload. This simplifies the client (one request, no coordination between requests), reduces latency, and eliminates the partial-save failure mode (where the day is saved but a block POST fails).

---

## 2. TargetSetRequest — wrap single set as one-element array

**Decision**: `ExerciseBlock` currently stores one `targetReps` + `targetWeight` (single set prescription). The API requires `targetSets: [...]`. Map the single block prescription to `targetSets: [TargetSetRequest(orderIndex: 1, targetReps: block.targetReps, targetWeight: block.targetWeight)]`.

**Rationale**: The UI supports one set of targets per block. Wrapping it as a one-element array satisfies the API contract without changing the `ExerciseBlock` domain model. Multi-set UI support is future scope.

---

## 3. isOptional defaults to false

**Decision**: `ExerciseBlock` has no `isOptional` field. Hardcode `isOptional: false` in `ExerciseBlockRequest.init(block:)`.

**Rationale**: Spec assumption: "The optional flag defaults to false for all newly created exercise blocks unless the user explicitly marks them optional." No UI toggle exists yet.

---

## 4. orderIndex for exercise blocks

**Decision**: Derive `exerciseBlock.orderIndex` from the block's 1-based position in `plan.blocks` (`enumerated` → `offset + 1`).

---

## 5. Accept 200 or 201 as success

**Decision**: Change the `guard http.statusCode == 201` check to `guard [200, 201].contains(http.statusCode)`.

**Rationale**: Spec FR-005: "On a successful save (any success response)." The user explicitly listed both 200 and 201 as valid success codes.

---

## 6. WorkoutDayPlanResponse — keep but make optional

**Decision**: Keep `WorkoutDayPlanResponse` struct (it may be returned by the server) but treat decoding as best-effort — the response body is not needed for the new flow. The service returns `Void` or discards the response body on success.

Actually, since there's no subsequent `saveExerciseBlock` call that needs `workoutDayPlanId`, the service's `saveDayPlan` can return `Void`. Keep the protocol signature returning `Void` for simplicity.

---

## 7. Remove saveExerciseBlock from protocol and service

**Decision**: Delete `saveExerciseBlock(workoutDayPlanId:request:)` from both `WorkoutDayPlanServiceProtocol` and `WorkoutDayPlanService`. The `ExerciseBlockPlanRequest` struct is also replaced by the new `ExerciseBlockRequest` (nested inside `WorkoutDayPlanRequest`).

**Rationale**: The exercise-block data is now part of the day plan request body. A separate endpoint is no longer called.

---

## All NEEDS CLARIFICATION Items

None — all decisions resolved above.
