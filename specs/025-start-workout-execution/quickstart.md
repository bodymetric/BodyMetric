# Quickstart: Start Workout Execution

**Branch**: `025-start-workout-execution` | **Date**: 2026-05-31

## Verification Scenarios

---

### Scenario 1 — Happy path: Begin Session navigates to active workout screen

**Setup**: `CheckInView` with `planId = 188`, `actualWeekNumber = 1`. Select mood "STRONG" (high). Mock service returns a `StartWorkoutResponse` with `workExecutionId = 9`, `workoutPlanName = "Push Day"`, `totalNumberOfSets = 4`, one `ExerciseBlockPlan` (exerciseName: "Inverted Row", 4 sets, restSeconds: 90, two `TargetSet`s: 8 reps @ 60kg).

**Expected**:
1. "Begin Session" button is tapped.
2. Button shows loading indicator and is disabled.
3. Navigation pushes to `ActiveSessionView`.
4. Active screen header shows plan name (visible in session header) and `workExecutionId = 9` stored.
5. Exercise list shows "Inverted Row" with 4 sets.
6. Each set row shows target reps and target weight from the plan.

---

### Scenario 2 — Request failure stays on check-in with error

**Setup**: Same as Scenario 1, but mock service throws a network error.

**Expected**:
1. "Begin Session" is tapped.
2. Button shows loading state, is disabled.
3. Request fails.
4. User stays on check-in screen.
5. Error message is visible.
6. Button is re-enabled; user can tap again.

---

### Scenario 3 — Exercise blocks displayed in orderIndex order

**Setup**: Response contains two `ExerciseBlockPlan`s — orderIndex 2: "Bench Press"; orderIndex 1: "Squat".

**Expected**: Active session shows "Squat" first (orderIndex 1), then "Bench Press" (orderIndex 2).

---

### Scenario 4 — Target sets displayed in orderIndex order within each block

**Setup**: One exercise block with two `TargetSet`s — orderIndex 2: 8 reps @ 50kg; orderIndex 1: 10 reps @ 40kg.

**Expected**: Set 1 shows 10 reps @ 40kg; Set 2 shows 8 reps @ 50kg.

---

### Scenario 5 — Build passes with zero errors

`xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` exits `BUILD SUCCEEDED`.
