# Data Model: Workout Plan Wizard — Step 2 Day & Exercise Persistence

**Feature**: `011-wizard-day-persist`  
**Date**: 2026-04-29

---

## 1. WorkoutDayPlanRequest (POST body for /api/workout-plans/{id}/days)

| Field | Type | Required | Source | Notes |
|-------|------|----------|--------|-------|
| `name` | `String` | yes | User input (session name field) | Non-empty; e.g. "Peito e Tríceps" |
| `orderIndex` | `Int` | yes | Derived: `day.rawValue - 1` | 0-based (Mon=0, Sun=6) |
| `isActive` | `Bool` | yes | Always `true` | Default on creation |

---

## 2. WorkoutDayPlanResponse (201 response from /api/workout-plans/{id}/days)

| Field | Type | Notes |
|-------|------|-------|
| `workoutDayPlanId` | `Int` | Required for exercise-block POSTs |

Additional fields may be present but are not consumed by the app in this feature.

**Conforms to**: `Decodable`, `Identifiable` (via `workoutDayPlanId`)

---

## 3. ExerciseBlockPlanRequest (POST body for /api/workout-day-plans/{id}/exercise-blocks)

| Field | Type | Required | Source | Notes |
|-------|------|----------|--------|-------|
| `exerciseId` | `String` | yes | User's selected exercise (`ExerciseBlock.exerciseId`) | Matches exercise catalog ID |
| `targetReps` | `Int` | yes | `ExerciseBlock.targetReps` | Minimum 1 |
| `targetWeightKg` | `Double` | yes | `ExerciseBlock.targetWeight` | 0 allowed (bodyweight) |
| `restSeconds` | `Int` | yes | `ExerciseBlock.restSeconds` | 0 allowed |

> ⚠️ **Field names unverified**: `targetWeightKg` and `restSeconds` are assumed. Verify against live API and adjust `CodingKeys` if needed.

---

## 4. ViewModel state additions (NewPlanViewModel)

| New Property | Type | Purpose |
|-------------|------|---------|
| `workoutPlanIds` | `[DayOfWeek: Int]` | Maps each selected day to its `planId` from step 1 response. Populated by updated `saveDays`. |
| `isDayConfigSaving` | `Bool` | True while step 2 save is in progress; disables Continue and prevents duplicate submits. |
| `dayConfigSaveError` | `String?` | Inline error message for step 2 failures; nil when no error. |

> Note: `isSaving` and `saveErrorMessage` already exist for step 1. New properties (`isDayConfigSaving`, `dayConfigSaveError`) are separate to avoid conflating step 1 and step 2 save states.

---

## 5. WorkoutPlanServiceProtocol change (backward-compatible)

**Before**: `func saveDays(_ days: [WorkoutPlanDayRequest]) async throws`  
**After**: `func saveDays(_ days: [WorkoutPlanDayRequest]) async throws -> [WorkoutPlanDayResponse]`

The added return value allows the caller to extract `planId` per day and store it in `workoutPlanIds`.

---

## 6. Save flow state machine

```
User taps Continue on step 2
    → isDayConfigSaving = true, dayConfigSaveError = nil
    → POST /api/workout-plans/{planId}/days
        → success: receive workoutDayPlanId
        → failure: isDayConfigSaving = false, dayConfigSaveError = message, STOP
    → for each ExerciseBlock in currentDayPlan.blocks:
        → POST /api/workout-day-plans/{workoutDayPlanId}/exercise-blocks
            → success: continue to next block
            → failure: isDayConfigSaving = false, dayConfigSaveError = message, STOP
    → all blocks saved: isDayConfigSaving = false, advance()
```

---

## 7. DayOfWeek → orderIndex mapping

| DayOfWeek | rawValue | orderIndex (rawValue - 1) |
|-----------|----------|--------------------------|
| .monday   | 1        | 0 |
| .tuesday  | 2        | 1 |
| .wednesday| 3        | 2 |
| .thursday | 4        | 3 |
| .friday   | 5        | 4 |
| .saturday | 6        | 5 |
| .sunday   | 7        | 6 |
