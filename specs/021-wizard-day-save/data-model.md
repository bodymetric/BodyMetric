# Data Model: Wizard Step 2 — Save Day Config on Continue

**Branch**: `021-wizard-day-save` | **Date**: 2026-05-31

## Entities (all existing — no new types)

### WorkoutDayPlanRequest

Serialised body for `POST /api/workout-plans/{workoutPlanId}/days`.

| Field | Type | Source | Constraints |
|-------|------|--------|-------------|
| name | String | `DayPlan.sessionName` | non-empty (validation gate) |
| orderIndex | Int | `DayOfWeek.orderIndex` | 0–6 (Mon=0, Sun=6) |
| isActive | Bool | constant | always `true` |
| exerciseBlocks | [ExerciseBlockRequest] | `DayPlan.blocks` | ≥ 1 block (validation gate) |

### ExerciseBlockRequest

One exercise block within the day plan request.

| Field | Type | Source | Constraints |
|-------|------|--------|-------------|
| exerciseId | Int | `Int(ExerciseBlock.exerciseId) ?? 0` | > 0 (validation gate ensures exerciseId is set) |
| orderIndex | Int | 1-based position in blocks list | ≥ 1 |
| restSeconds | Int | `ExerciseBlock.restSeconds` | 0–600 |
| isOptional | Bool | constant | always `false` |
| targetSets | [TargetSetRequest] | `ExerciseBlock.sets` | ≥ 1 set (validation gate) |

### TargetSetRequest

One target set within an exercise block request.

| Field | Type | Source | Constraints |
|-------|------|--------|-------------|
| orderIndex | Int | 1-based position in sets list | ≥ 1 |
| targetReps | Int | `SetConfig.targetReps` | ≥ 1 (validation gate) |
| targetWeight | Double | `SetConfig.targetWeight` | ≥ 0.0 (bodyweight = 0) |

## Relationships

```
WorkoutDayPlanRequest
└── [ExerciseBlockRequest] (1:many, ordered by orderIndex)
    └── [TargetSetRequest]  (1:many, ordered by orderIndex)
```

## Source Model Mapping

```
DayPlan.sessionName             → WorkoutDayPlanRequest.name
DayOfWeek.orderIndex            → WorkoutDayPlanRequest.orderIndex
constant true                   → WorkoutDayPlanRequest.isActive
DayPlan.blocks[i]               → WorkoutDayPlanRequest.exerciseBlocks[i]
  ExerciseBlock.exerciseId      → ExerciseBlockRequest.exerciseId
  (i + 1)                       → ExerciseBlockRequest.orderIndex
  ExerciseBlock.restSeconds     → ExerciseBlockRequest.restSeconds
  constant false                → ExerciseBlockRequest.isOptional
  ExerciseBlock.sets[j]         → ExerciseBlockRequest.targetSets[j]
    (j + 1)                     → TargetSetRequest.orderIndex
    SetConfig.targetReps        → TargetSetRequest.targetReps
    SetConfig.targetWeight      → TargetSetRequest.targetWeight
```

## State (ViewModel)

| Property | Type | Role |
|----------|------|------|
| `workoutPlanIds: [DayOfWeek: Int]` | Dictionary | Maps each day to its server-assigned plan ID (populated from step 1 response) |
| `isDayConfigSaving: Bool` | Bool | True while save is in flight; gates the Continue button |
| `dayConfigSaveError: String?` | Optional String | Set on failure; cleared at start of next attempt |
