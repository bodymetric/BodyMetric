# Quickstart: Wizard Step 2 — Save Day Config on Continue

**Branch**: `021-wizard-day-save` | **Date**: 2026-05-31

## Integration Scenarios

All scenarios below are already passing. These are verification checkpoints.

---

### Scenario 1 — Correct URL and method

**Setup**: `WorkoutDayPlanService.saveDayPlan(workoutPlanId: 7, request: ...)`.

**Expected**: `POST https://api.bodymetric.com.br/api/workout-plans/7/days`

---

### Scenario 2 — Full payload with per-set data

**Setup**: A `DayPlan` with `sessionName = "Peito e Tríceps"`, one `ExerciseBlock` (`exerciseId = "1"`, `restSeconds = 60`), one `SetConfig` (`targetReps = 12, targetWeight = 25.0`).

**Expected request body**:
```json
{
  "name": "Peito e Tríceps",
  "orderIndex": 0,
  "isActive": true,
  "exerciseBlocks": [
    {
      "exerciseId": 1,
      "orderIndex": 1,
      "restSeconds": 60,
      "isOptional": false,
      "targetSets": [
        { "orderIndex": 1, "targetReps": 12, "targetWeight": 25.0 }
      ]
    }
  ]
}
```

---

### Scenario 3 — Continue button disabled during save

**Setup**: `sut.isDayConfigSaving = true`.

**Expected**: `canContinue && !stepDaySaving` evaluates to `false`; button is non-interactive.

---

### Scenario 4 — Error shown on save failure; wizard stays on step 2

**Setup**: `MockWorkoutDayPlanService` throws `WorkoutPlanError.serverError(500)`.

**Expected**:
- `sut.dayConfigSaveError == "Could not save your workout day. Please try again."`
- `onSuccess` callback NOT called
- `sut.currentStep` unchanged (wizard did not advance)

---

### Scenario 5 — Error cleared on retry

**Setup**: First call fails (sets `dayConfigSaveError`); second call succeeds.

**Expected**: At start of second call, `dayConfigSaveError == nil`; after success, `dayConfigSaveError` remains nil.

---

### Scenario 6 — Build passes with zero errors

`xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` exits `BUILD SUCCEEDED`.
