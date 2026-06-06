# Data Model: Start Workout Execution

**Branch**: `025-start-workout-execution` | **Date**: 2026-05-31

## API DTOs (in `Models/WorkoutExecutionModels.swift`)

### StartSessionRequest (unchanged)

Sent to `POST /api/work-executions/start`.

| Field | Type | Notes |
|-------|------|-------|
| `planId` | `Int` | Selected workout plan ID |
| `actualWeekNumber` | `Int` | Hardcoded `1` |
| `feeling` | `String` | Uppercase mood: `"LOW"`, `"OK"`, `"HIGH"` |

---

### StartWorkoutResponse (replaces `StartSessionResponse`)

Top-level response from the server.

| Field | Type | Notes |
|-------|------|-------|
| `workExecutionId` | `Int` | Session ID for subsequent progress calls |
| `workoutPlanId` | `Int` | |
| `workoutPlanName` | `String` | Displayed on active screen |
| `totalNumberOfSets` | `Int` | Total sets across all exercise blocks |
| `exerciseBlockPlans` | `[ExerciseBlockPlan]` | Ordered by `orderIndex` before display |

Must conform to `Decodable, Hashable` (used in `NavigationPath`).

---

### ExerciseBlockPlan (replaces `SessionExercise`)

One exercise block within the session.

| Field | Type | Notes |
|-------|------|-------|
| `exerciseBlockPlanId` | `Int` | Block ID for future calls |
| `exerciseId` | `Int` | |
| `exerciseName` | `String` | Displayed in card header |
| `orderIndex` | `Int` | Sort key for display order |
| `restSeconds` | `Int` | Rest timer duration after each set |
| `isOptional` | `Bool` | |
| `numberOfSets` | `Int` | Number of target sets |
| `targetSets` | `[TargetSet]` | Ordered by `orderIndex` before display |

---

### TargetSet (replaces `SessionSet`)

One planned set within an exercise block.

| Field | Type | Notes |
|-------|------|-------|
| `targetSetId` | `Int` | |
| `orderIndex` | `Int` | Sort key for display order |
| `targetReps` | `Int` | Prescribed rep count |
| `targetWeight` | `Double` | Prescribed weight in kg |

---

## Domain Models (in `Features/Workout/Models/WorkoutModels.swift`)

These are the in-memory models used by `ActiveSessionViewModel` and all views.

### WorkoutSession (updated)

| Field | Type | Change |
|-------|------|--------|
| `id` | `Int` | Was `String` — now Int (workExecutionId) |
| `name` | `String` | Set to `workoutPlanName` |
| `totalSets` | `Int` | Computed from exercises or mapped from `totalNumberOfSets` |
| `exercises` | `[WorkoutExercise]` | Sorted by `orderIndex` |

### WorkoutExercise (updated)

| Field | Type | Change |
|-------|------|--------|
| `exerciseBlockPlanId` | `Int` | **Added** — mapped from `ExerciseBlockPlan.exerciseBlockPlanId` |
| `id` | `Int` | Was `String` — now Int (exerciseId) |
| `name` | `String` | Mapped from `exerciseName` |
| `restSeconds` | `Int` | Unchanged |
| `sets` | `[WorkoutSet]` | Sorted by `orderIndex` |
| ~~`muscle`~~ | ~~`String`~~ | **Removed** — not in new API |
| ~~`pr`~~ | ~~`PRRecord?`~~ | **Removed** — not in new API |

### WorkoutSet (updated)

| Field | Type | Change |
|-------|------|--------|
| `targetReps` | `Int` | Unchanged |
| `targetWeight` | `Double` | **New** — replaces `prevWeight`/`prevReps` |
| ~~`prevWeight`~~ | ~~`Double`~~ | **Removed** |
| ~~`prevReps`~~ | ~~`Int`~~ | **Removed** |

### SetProgress (updated)

| Field | Type | Change |
|-------|------|--------|
| `done` | `Bool` | Unchanged |
| `weight` | `Double` | Unchanged (current logged weight) |
| `reps` | `Int` | Unchanged (current logged reps) |
| `targetReps` | `Int` | Unchanged |
| `targetWeight` | `Double` | **New** — replaces `prevWeight`/`prevReps` |
| ~~`prevWeight`~~ | ~~`Double`~~ | **Removed** |
| ~~`prevReps`~~ | ~~`Int`~~ | **Removed** |

---

## Mapping: `StartWorkoutResponse → WorkoutSession`

`StartWorkoutResponse.toWorkoutSession()` → new mapping:

```
workExecutionId   → WorkoutSession.id (Int)
workoutPlanName   → WorkoutSession.name
exerciseBlockPlans (sorted by orderIndex) → exercises: [WorkoutExercise]

  ExerciseBlockPlan:
    exerciseBlockPlanId → WorkoutExercise.exerciseBlockPlanId
    exerciseId          → WorkoutExercise.id
    exerciseName        → WorkoutExercise.name
    restSeconds         → WorkoutExercise.restSeconds
    targetSets (sorted by orderIndex) → WorkoutExercise.sets: [WorkoutSet]

      TargetSet:
        targetReps   → WorkoutSet.targetReps
        targetWeight → WorkoutSet.targetWeight
```

---

## `ActiveSessionViewModel` (updated)

| Property | Type | Change |
|----------|------|--------|
| `workExecutionId` | `Int` | **Added** — retained for future save calls |
| `workout` | `WorkoutSession` | Unchanged |
| `mood` | `String` | Unchanged — passed from `CheckInView` state |

Init signature change:
```swift
// Before:
init(workout: WorkoutSession, mood: String)

// After:
init(workExecutionId: Int, workout: WorkoutSession, mood: String)
```
