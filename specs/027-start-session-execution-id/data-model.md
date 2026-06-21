# Data Model: Start Session Returns Exercise Block Execution ID

**Feature**: `027-start-session-execution-id`  
**Date**: 2026-06-21

---

## Changed Entity: ExerciseBlockPlan (Decodable)

| Field | Type (026 bug fix) | Type (this feature) | Source | Notes |
|-------|---------------------|---------------------|--------|-------|
| `exerciseBlockPlanId` | `Int` | `Int` | JSON | Unchanged |
| `exerciseBlockExecutionId` | `Int?` | `Int` | JSON | **Changed back to required** — server now always returns this field |
| `exerciseId` | `Int` | `Int` | JSON | Unchanged |
| `exerciseName` | `String` | `String` | JSON | Unchanged |
| `orderIndex` | `Int` | `Int` | JSON | Unchanged |
| `restSeconds` | `Int` | `Int` | JSON | Unchanged |
| `isOptional` | `Bool` | `Bool` | JSON | Unchanged |
| `numberOfSets` | `Int` | `Int` | JSON | Unchanged |
| `targetSets` | `[TargetSet]` | `[TargetSet]` | JSON | Unchanged |

**Validation**: If `exerciseBlockExecutionId` is absent from the JSON, `JSONDecoder` throws `DecodingError.keyNotFound`. This is the intended behavior per FR-006 and US3 — the decode failure is surfaced as an error on the check-in screen.

---

## Unchanged Entity: WorkoutExercise (in-memory)

| Field | Type | Source (after this feature) | Notes |
|-------|------|-----------------------------|-------|
| `exerciseBlockPlanId` | `Int` | `ExerciseBlockPlan.exerciseBlockPlanId` | Unchanged |
| `exerciseBlockExecutionId` | `Int` | `ExerciseBlockPlan.exerciseBlockExecutionId` | **Mapping simplified** — `?? 0` removed; direct pass-through |
| `id` | `Int` | `ExerciseBlockPlan.exerciseId` | Unchanged |
| `name` | `String` | `ExerciseBlockPlan.exerciseName` | Unchanged |
| `restSeconds` | `Int` | `ExerciseBlockPlan.restSeconds` | Unchanged |
| `sets` | `[WorkoutSet]` | `ExerciseBlockPlan.targetSets` | Unchanged |

---

## State Transition: commitSet guard (unchanged, context updated)

```
exerciseBlockExecutionId == 0
    → logError = "Cannot log set: invalid session data. Please end and restart the session."
    → return (no API call)
    [Triggered only if server sends 0, which is semantically invalid]

exerciseBlockExecutionId > 0
    → proceed to PerformedSetService.logPerformedSet(...)
    [Normal path — all blocks from the server have valid positive IDs]
```

---

## Decode Error Flow: Missing `exerciseBlockExecutionId` (US3)

```
Server omits exerciseBlockExecutionId
    → JSONDecoder throws DecodingError.keyNotFound
    → WorkoutExecutionService.startSession catches → throws WorkoutPlanError.decodingError
    → ReadyToLiftViewModel.beginSession catches → loadState = .failed("Could not read the server response.")
    → CheckInView shows error banner
    → User remains on check-in screen ✓
```
