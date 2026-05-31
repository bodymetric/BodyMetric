# Data Model: Home API — Replace targetSets with numberOfSets

**Branch**: `019-home-api-numberofsets` | **Date**: 2026-05-24

## Entities

### HomeScreenData

Root response from `GET /api/home?currentDayOfWeek={DAY}`.

| Field | Type | Notes |
|-------|------|-------|
| currentWorkoutDayPlan | WorkoutDayPlanSummary? | nil when no plan exists for today |
| exercisesForToday | [TodayExercise]? | nil or empty when no exercises scheduled |

### WorkoutDayPlanSummary

Summary card data for the home workout tile.

| Field | Type | Notes |
|-------|------|-------|
| id | Int | server-assigned plan day ID |
| name | String | e.g., "Chest and Triceps" |
| dayOfWeek | String | UPPERCASE, e.g., "MONDAY" |
| numberOfExercisesTotal | Int | exercise count for this day |
| numberSetsTotal | Int | **new** — total set count across all exercises |
| timeEstimateToFinish | Int | estimated duration in minutes |
| actualWeekNumber | Int? | server-tracked training week; optional |

### TodayExercise

One exercise entry in today's ordered list.

| Field | Type | Notes |
|-------|------|-------|
| id | Int | server-assigned exercise ID |
| name | String | e.g., "Dumbbell Curl" |
| orderIndex | Int | 1-based display order; exercises sorted ascending |
| numberOfSets | Int | **replaces** `sets: [TodayExerciseSet]` |

### TodayExerciseSet — DELETED

This type is removed. It was used to express individual set configurations (targetReps, targetWeight, orderIndex) per exercise. The home screen only needs the count; detailed set data is loaded separately during workout execution.

## Relationships

```
HomeScreenData
├── WorkoutDayPlanSummary? (1:1)
└── [TodayExercise] (1:many, ordered by orderIndex)
```

## Validation Rules

- `numberOfSets` must be ≥ 0; display "–" or omit if 0 (defensive, server should never return 0)
- `numberSetsTotal` must be ≥ 0
- `orderIndex` values may be non-contiguous; UI sorts ascending, no gaps assumed
- `dayOfWeek` is UPPERCASE; UI displays formatted version

## State Transitions

No state transitions on entities — home screen data is read-only. Exercises are fetched fresh on every screen visit.
