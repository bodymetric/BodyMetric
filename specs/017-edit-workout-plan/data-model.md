# Data Model: Edit Existing Workout Plan

**Branch**: `017-edit-workout-plan`  
**Date**: 2026-05-17

---

## Existing Entities (unchanged)

| Entity | Location | Notes |
|--------|----------|-------|
| `ExerciseBlock` | `Features/NewPlan/Models/NewPlanModels.swift` | Wizard in-memory block; `exerciseId: String` |
| `DayPlan` | `Features/NewPlan/Models/NewPlanModels.swift` | One training day in the wizard |
| `WorkoutPlan` (local) | `Features/NewPlan/Models/NewPlanModels.swift` | Local persisted plan (UserDefaults) |
| `WorkoutPlanDayResponse` | `Models/WorkoutPlanModels.swift` | GET /api/workout-plans response entry |
| `WorkoutDayPlanRequest` | `Models/WorkoutDayPlanModels.swift` | POST /api/workout-plans/{id}/days body |
| `ExerciseBlockRequest` | `Models/WorkoutDayPlanModels.swift` | Exercise block within day plan request |
| `TargetSetRequest` | `Models/WorkoutDayPlanModels.swift` | One set within an exercise block request |

---

## New Entities

### `CurrentWorkoutPlan` — GET /api/workout-plans/current response

Decoded from the top-level JSON object returned by `GET /api/workout-plans/current`.

```swift
struct CurrentWorkoutPlan: Decodable {
    let id: Int                            // plan's server-side ID — used in PUT URL
    let days: [CurrentWorkoutPlanDay]      // ordered list of configured training days
}
```

**Relationships**: Contains 1..n `CurrentWorkoutPlanDay` entries.

---

### `CurrentWorkoutPlanDay` — one training day within the current plan

```swift
struct CurrentWorkoutPlanDay: Decodable {
    let id: Int                            // day plan ID (maps to workoutPlanIds[day] in ViewModel)
    let plannedDayOfWeek: String           // "MONDAY"–"SUNDAY" — used for DayOfWeek pre-fill
    let name: String                       // session name, e.g. "Chest Day"
    let orderIndex: Int                    // display order; used during pre-fill
    let exerciseBlocks: [CurrentExerciseBlock]
}
```

**Relationships**: Belongs to `CurrentWorkoutPlan`; contains 0..n `CurrentExerciseBlock` entries.

---

### `CurrentExerciseBlock` — one exercise within a training day

```swift
struct CurrentExerciseBlock: Decodable {
    let exerciseId: Int                    // catalog exercise ID — converted to String for ExerciseBlock
    let orderIndex: Int                    // sort order within the day
    let restSeconds: Int                   // rest time in seconds
    let targetSets: [CurrentTargetSet]     // at least one set expected
}
```

**Relationships**: Belongs to `CurrentWorkoutPlanDay`; contains 1..n `CurrentTargetSet` entries.

---

### `CurrentTargetSet` — one target set within an exercise block

```swift
struct CurrentTargetSet: Decodable {
    let orderIndex: Int                    // sort order within the block
    let targetReps: Int                    // target rep count
    let targetWeight: Double               // target weight in kg
}
```

**Note**: The wizard's `ExerciseBlock` holds a single set (`targetReps`, `targetWeight`, `restSeconds`). When a block has multiple sets in the API response, only the first set (sorted by `orderIndex`) is used for pre-fill in v1 — the wizard currently models one prescription per block.

---

### `UpdateWorkoutPlanRequest` — PUT /api/workout-plans/{id} body

```swift
struct UpdateWorkoutPlanRequest: Codable {
    let days: [UpdateWorkoutPlanDayRequest]
}

struct UpdateWorkoutPlanDayRequest: Codable {
    let plannedDayOfWeek: String           // e.g. "monday"
    let name: String                       // session name
    let orderIndex: Int                    // weekday order index (Mon=0, Sun=6)
    let isActive: Bool                     // always true for active days
    let exerciseBlocks: [ExerciseBlockRequest]  // reuses existing type
}
```

**Rationale for reusing `ExerciseBlockRequest`**: The update payload structure mirrors the creation payload. `ExerciseBlockRequest` already encodes `exerciseId`, `orderIndex`, `restSeconds`, `isOptional`, and `targetSets` — exactly what the PUT endpoint needs.

---

## ViewModel State Additions

### `NewPlanViewModel` new properties

| Property | Type | Purpose |
|----------|------|---------|
| `planId` | `Int?` | Server ID of the plan being edited; `nil` in create mode |
| `editPlanLoadState` | `EditPlanLoadState` | Tracks async load of existing plan data |

### `EditPlanLoadState` enum

```swift
enum EditPlanLoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
}
```

---

## Menu Navigation Extension

### `HomeMenuDestination` additions

```swift
enum HomeMenuDestination: Equatable, Hashable, Identifiable {
    case today
    case newWorkoutPlan
    case editPlan            // NEW — opens wizard with existing plan pre-filled
}
```

---

## Pre-fill Mapping Rules

| API field | Wizard field | Conversion |
|-----------|-------------|------------|
| `CurrentWorkoutPlan.id` | `NewPlanViewModel.planId` | Direct |
| `CurrentWorkoutPlanDay.plannedDayOfWeek` | `selectedDays` | `DayOfWeek(fromApiString:)` |
| `CurrentWorkoutPlanDay.id` | `workoutPlanIds[day]` | Direct |
| `CurrentWorkoutPlanDay.name` | `dayPlans[day]?.sessionName` | Direct |
| `CurrentExerciseBlock.exerciseId` | `ExerciseBlock.exerciseId` | `String(Int)` |
| `CurrentExerciseBlock.orderIndex` | block position in `dayPlans[day]?.blocks` | Sort by orderIndex, then index |
| `CurrentExerciseBlock.restSeconds` | `ExerciseBlock.restSeconds` | Direct |
| `CurrentTargetSet[0].targetReps` | `ExerciseBlock.targetReps` | First set only (v1) |
| `CurrentTargetSet[0].targetWeight` | `ExerciseBlock.targetWeight` | First set only (v1) |
