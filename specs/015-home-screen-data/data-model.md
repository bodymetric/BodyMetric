# Data Model: Home Screen Live Data

**Date**: 2026-05-03

---

## GET /api/home response

### HomeScreenData

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `currentWorkoutDayPlan` | `WorkoutDayPlanSummary?` | no | Present if user has an active plan today |
| `exercisesForToday` | `[TodayExercise]?` | no | Today's exercises; nil or empty = no card shown |

**Conforms to**: `Decodable`

---

### WorkoutDayPlanSummary

| Field | Type | Description |
|-------|------|-------------|
| `name` | `String` | Session name (e.g., "Peito e Tríceps") |
| `numberOfExercisesTotal` | `Int` | Total number of exercises in the day |
| `numberSetsTotal` | `Int` | Total sets across all exercises |
| `timeEstimateToFinishes` | `Int` | Estimated duration in minutes |

**Conforms to**: `Decodable`

---

### TodayExercise

| Field | Type | Description |
|-------|------|-------------|
| `id` | `Int` | Stable identifier |
| `name` | `String` | Display name |

Additional server fields are silently ignored. **Conforms to**: `Decodable`, `Identifiable`

---

## TodayViewModel state machine

```
.idle
  ↓ (TodayView .task fires)
.loading  ←──────────────────────────────────┐
  ↓ 200 OK                                   │
.loaded(HomeScreenData)                      │ retry
  ↓ hasActivePlan = data.currentWorkoutDayPlan != nil
                                             │
.failed(message) ──── user taps Retry ───────┘
```

### Derived properties

| Property | Derived from |
|----------|-------------|
| `hasActivePlan: Bool` | `case .loaded(let d) = loadState → d.currentWorkoutDayPlan != nil` |
| `workoutPlan: WorkoutDayPlanSummary?` | extracted from loaded state |
| `exercisesForToday: [TodayExercise]` | extracted from loaded state; empty array if nil |

---

## TodayView rendering rules

| `loadState` | Workout card | Exercises card | Menu "New Plan" | Menu "My Plans" |
|-------------|-------------|----------------|-----------------|-----------------|
| `.idle` / `.loading` | Skeleton | Skeleton | — | — |
| `.loaded`, no plan | Empty state + "New Workout Plan" button | Hidden | Enabled | Disabled |
| `.loaded`, has plan | Populated (name/exercises/sets/time) + "Start Workout" | Shown if non-empty | Disabled | Enabled |
| `.failed` | Error banner | Hidden | — | — |
