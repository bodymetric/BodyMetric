# Data Model: Wizard Step 2 — Per-Set Row Configuration

**Branch**: `020-wizard-step2-per-set-rows` | **Date**: 2026-05-28

## Entities

### SetConfig *(new)*

One individual set row within an exercise block.

| Field | Type | Default | Constraints |
|-------|------|---------|-------------|
| id | UUID | UUID() | auto-generated; used by ForEach identity |
| targetReps | Int | 8 | min 1, max 50 |
| targetWeight | Double | 60.0 | min 0 (bodyweight), max 500 kg; displayed with 1 decimal if fractional |

### ExerciseBlock *(updated)*

One exercise slot within a training day. Replaces scalar `numberOfSets + targetReps + targetWeight` with `sets: [SetConfig]`.

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| id | UUID | UUID() | block identity |
| exerciseId | String | "" | empty = not yet picked |
| sets | [SetConfig] | 4 × SetConfig() | min 1 set, soft max 20; ordered by array index |
| restSeconds | Int | 90 | per-block, not per-set; min 0, max 600 |

**isValid** rule: `!exerciseId.isEmpty && !sets.isEmpty && sets.allSatisfy { $0.targetReps >= 1 && $0.targetWeight >= 0 } && restSeconds >= 0`

### DayPlan *(unchanged)*

| Field | Type | Notes |
|-------|------|-------|
| day | DayOfWeek | |
| sessionName | String | must be non-blank for DayPlan.isValid |
| blocks | [ExerciseBlock] | min 1 block |

### TargetSetRequest *(unchanged)*

Used in the API request body. One entry per set in `block.sets`.

| Field | Type | Notes |
|-------|------|-------|
| orderIndex | Int | 1-based; derived from `block.sets` index |
| targetReps | Int | from `SetConfig.targetReps` |
| targetWeight | Double | from `SetConfig.targetWeight` |

## Removed Fields

The following fields are **removed** from `ExerciseBlock`:

| Field | Replaced by |
|-------|-------------|
| `numberOfSets: Int` | `sets.count` |
| `targetReps: Int` | `sets[i].targetReps` |
| `targetWeight: Double` | `sets[i].targetWeight` |

## Relationships

```
DayPlan
└── [ExerciseBlock] (1:many, ordered)
    └── [SetConfig] (1:many, ordered by array index)
```

## Validation Rules

- `ExerciseBlock.isValid` now checks `!sets.isEmpty && sets.allSatisfy { $0.targetReps >= 1 && $0.targetWeight >= 0 }`
- Minimum 1 `SetConfig` per block (enforced by hiding × when `sets.count == 1`)
- `SetConfig.targetReps` minimum 1 (− stepper disabled at 1)
- `SetConfig.targetWeight` minimum 0 (bodyweight; − stepper disabled at 0)
- `ExerciseBlock.restSeconds` minimum 0, maximum 600

## API Mapping

`ExerciseBlockRequest.init(block:orderIndex:)` generates `targetSets` from `block.sets`:

```
block.sets[0] → TargetSetRequest(orderIndex: 1, targetReps: sets[0].targetReps, targetWeight: sets[0].targetWeight)
block.sets[1] → TargetSetRequest(orderIndex: 2, ...)
...
```

The server-side `targetSets` array shape is **unchanged** — only the client-side source of truth changes.

---

## Amendment: Home Screen DTOs (2026-05-28)

### HomeExerciseSet *(restored)*

One set entry within `TodayExercise.sets`, decoded from `GET /api/home`.

| Field | Type | Notes |
|-------|------|-------|
| orderIndex | Int | 1-based; used for display ordering |
| targetReps | Int | target rep count |
| targetWeight | Double | target weight in kg |

### TodayExercise *(updated)*

| Field | Type | Before (broken) | After (fixed) |
|-------|------|-----------------|---------------|
| id | Int | ✅ unchanged | ✅ unchanged |
| name | String | ✅ unchanged | ✅ unchanged |
| orderIndex | Int | ✅ unchanged | ✅ unchanged |
| sets | [HomeExerciseSet] | removed (feature 019 bug) | ✅ restored |
| numberOfSets | Int | `let numberOfSets: Int` (broken — key missing from server) | `var numberOfSets: Int { sets.count }` (computed) |

### HomeScreenData *(unchanged)*

```swift
struct HomeScreenData: Decodable, Equatable {
    let currentWorkoutDayPlan: WorkoutDayPlanSummary?
    let exercisesForToday: [TodayExercise]?
}
```

### WorkoutDayPlanSummary *(unchanged)*

All fields already decode correctly from the server response. `actualWeekNumber: Int?` is Optional so it decodes as `nil` when absent.
