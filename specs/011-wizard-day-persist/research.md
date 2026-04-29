# Research: Workout Plan Wizard — Step 2 Day & Exercise Persistence

**Feature**: `011-wizard-day-persist`  
**Date**: 2026-04-29

---

## 1. WorkoutPlanService.saveDays must return the response body

**Issue**: `WorkoutPlanService.saveDays(_:)` currently accepts 201 and returns `Void`, discarding the response body. Step 2 needs the `planId` from each created workout-plan-day entry to POST the day plan to the correct URL (`/api/workout-plans/{planId}/days`).

**Decision**: Update `WorkoutPlanServiceProtocol.saveDays` to return `[WorkoutPlanDayResponse]`. Update the concrete service to decode the 201 body. Update `NewPlanViewModel.saveDays` to store the returned `planIds` in a new `workoutPlanIds: [DayOfWeek: Int]` dictionary. Update the mock and tests.

**Rationale**: The step 1 API response already provides `planId` per day (via `WorkoutPlanDayResponse.planId`). Storing this mapping in the ViewModel is the simplest way to make `planId` available for step 2 without additional network calls.

**Alternatives considered**:
- Separate GET to load planIds before step 2 — rejected; adds latency; planIds are already returned by step 1 POST.
- Pass planId directly to `ConfigureDayStepView` — rejected; the ViewModel is the single source of truth for wizard state.

---

## 2. orderIndex derivation

**Decision**: `orderIndex = day.rawValue - 1`. Since `DayOfWeek.rawValue` is 1-based (Monday = 1, Sunday = 7), subtracting 1 gives a 0-based index (Monday = 0, Sunday = 6).

**Rationale**: The API example shows `orderIndex: 6` for Sunday (`plannedWeekNumber: 7`, rawValue = 7). `7 - 1 = 6`. This is consistent and derivable purely from the `DayOfWeek` enum without needing any positional context from the selection.

**Alternatives considered**:
- 0-based position within `orderedSelectedDays` — rejected; this would change if the user deselects a day; `rawValue - 1` is deterministic and stable.

---

## 3. ExerciseBlockPlan request body field names

**Issue**: The user specified "Send the corresponding ExerciseBlockPlan data filled in by the user" without naming the exact JSON fields for the exercise block POST.

**Decision**: Assume the following field names based on the existing `ExerciseBlock` Swift model and common REST naming conventions. **These must be verified against actual API documentation before implementation.**

Assumed request body for `POST /api/workout-day-plans/{id}/exercise-blocks`:
```json
{
    "exerciseId": "bench",
    "targetReps": 8,
    "targetWeightKg": 60.0,
    "restSeconds": 90
}
```

**Note**: If the actual field names differ (e.g., `weight` instead of `targetWeightKg`, or `reps` instead of `targetReps`), only the `ExerciseBlockPlanRequest` Codable struct's `CodingKeys` mapping needs updating — no ViewModel or View changes required.

**Alternatives considered**:
- Mark as NEEDS CLARIFICATION — rejected; the scope impact is limited to one Codable struct; a reasonable default is better than blocking planning.

---

## 4. Sequential vs parallel exercise-block POSTs

**Decision**: Save exercise blocks **sequentially** (one at a time), not in parallel.

**Rationale**: The server must assign stable IDs to each block. Parallel POSTs risk race conditions on the server's insertion order. Sequential saves are simpler to test and debug. With typical 2–5 blocks per day, sequential saves complete within the user-acceptable window.

**Alternatives considered**:
- `TaskGroup` for parallel POSTs — rejected for v1; latency gain is marginal; adds complexity.

---

## 5. Error handling strategy: first failure stops the sequence

**Decision**: If any POST (day plan or any exercise block) fails, immediately surface the error and stop. Do not attempt to save remaining blocks. The user retries the full step-2 save (the server is expected to handle idempotent retries).

**Rationale**: Spec FR-010/FR-011: "If any request fails, show a user-friendly error message and keep the user on the same step." Partial saves that leave incomplete state on the server are worse than retrying the full operation.

**Alternatives considered**:
- Continue saving remaining blocks after one fails — rejected; produces orphaned blocks linked to a day that may be in an inconsistent state.

---

## 6. New service placement

**Decision**: `WorkoutDayPlanService` placed at `Services/WorkoutPlan/` alongside `WorkoutPlanService`. Injected into `NewPlanWizardView` via a second `dayConfigService` parameter. `TodayView` creates both concrete services from the `networkClient` it already holds.

**Rationale**: Follows the established `WorkoutPlanService` injection pattern from feature 008. `TodayView` already has `networkClient: any NetworkClientProtocol`, so no additional plumbing through `MainTabView` or `BodyMetricApp` is needed.

**Alternatives considered**:
- Single merged service — rejected; separation of concerns makes testing cleaner.
- Pass raw `networkClient` to wizard and create services inside — acceptable, but making them explicit parameters is cleaner for testing.

---

## All NEEDS CLARIFICATION Items

None — all gaps resolved. Exercise block field names are assumed; implementation must verify against live API.
