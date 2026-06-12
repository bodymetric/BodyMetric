# Data Model: Log Set Performed

**Feature**: `026-log-set-performed`  
**Date**: 2026-06-11

---

## Entities

### LogPerformedSetRequest (new)

Request body sent to `POST /api/exercise-block-executions/{exerciseBlockExecutionId}/performed-sets`.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `weight` | `Double` | ≥ 0.0 | User-entered weight in kg; 0 valid for bodyweight |
| `reps` | `Int` | ≥ 1 | User-entered reps; 0 blocked by FR-007 |

### ExerciseBlockPlan (extended)

Existing struct in `Models/WorkoutExecutionModels.swift`. Gains one new field.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `exerciseBlockPlanId` | `Int` | server-assigned | plan-level ID (existing) |
| `exerciseBlockExecutionId` | `Int` | server-assigned | **NEW** — execution-level ID for this session |
| `exerciseId` | `Int` | server-assigned | (existing) |
| `exerciseName` | `String` | non-empty | (existing) |
| `orderIndex` | `Int` | ≥ 0 | (existing) |
| `restSeconds` | `Int` | ≥ 0 | (existing) |
| `isOptional` | `Bool` | — | (existing) |
| `numberOfSets` | `Int` | ≥ 1 | (existing) |
| `targetSets` | `[TargetSet]` | non-empty | (existing) |

### WorkoutExercise (extended)

Existing struct in `Features/Workout/Models/WorkoutModels.swift`. Gains one new field.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `exerciseBlockPlanId` | `Int` | — | plan-level ID (existing) |
| `exerciseBlockExecutionId` | `Int` | — | **NEW** — used as the URL path param when logging sets |
| `id` | `Int` | — | exerciseId (existing) |
| `name` | `String` | non-empty | (existing) |
| `restSeconds` | `Int` | ≥ 0 | (existing) |
| `sets` | `[WorkoutSet]` | non-empty | (existing) |

---

## State Transitions

### ActiveSessionViewModel — log submission lifecycle

```
idle
 │
 ├─ commitSet(exIdx, setIdx, weight, reps) called
 │   │
 │   ├─ reps == 0  →  logError = "Reps must be at least 1"  →  idle (no network call)
 │   │
 │   └─ reps > 0   →  isSubmittingLog = true
 │                     │
 │                     ├─ service.logPerformedSet() succeeds
 │                     │     → isSubmittingLog = false
 │                     │     → logError = nil
 │                     │     → SetProgress.done = true
 │                     │     → logTarget = nil (sheet closes)
 │                     │     → rest timer starts
 │                     │
 │                     └─ service.logPerformedSet() throws
 │                           → isSubmittingLog = false
 │                           → logError = "Failed to log set. Please try again."
 │                           → sheet stays open (user can retry)
```

---

## Mapping: API → Domain

`ExerciseBlockPlan.exerciseBlockExecutionId` (from API response)  
→ `WorkoutExercise.exerciseBlockExecutionId` (domain model)  
→ URL path segment in `PerformedSetService.logPerformedSet(exerciseBlockExecutionId:weight:reps:)`
