# Data Model: Home Screen Workout Data — Corrected API Contract

**Date**: 2026-05-03

---

## Corrected response DTOs (Models/HomeModels.swift)

### HomeScreenData — unchanged

```swift
struct HomeScreenData: Decodable, Equatable {
    let currentWorkoutDayPlan: WorkoutDayPlanSummary?
    let exercisesForToday: [TodayExercise]?
}
```

### WorkoutDayPlanSummary — updated

```swift
// BEFORE (015)                        // AFTER (016)
struct WorkoutDayPlanSummary {         struct WorkoutDayPlanSummary {
    let name: String                       let id: Int                   ← NEW
    let numberOfExercisesTotal: Int        let name: String
    let numberSetsTotal: Int               let dayOfWeek: String         ← NEW
    let timeEstimateToFinishes: Int        let numberOfExercisesTotal: Int
}                                          let numberSetsTotal: Int
                                           let timeEstimateToFinish: Int  ← RENAMED
                                       }
```

### TodayExercise — updated

```swift
// BEFORE (015)                        // AFTER (016)
struct TodayExercise {                 struct TodayExercise {
    let id: Int                            let id: Int
    let name: String                       let name: String
}                                          let orderIndex: Int            ← NEW
                                           let sets: [TodayExerciseSet]   ← NEW
                                       }
```

### TodayExerciseSet — NEW

```swift
struct TodayExerciseSet: Decodable, Equatable {
    let orderIndex: Int
    let targetReps: Int
    let targetWeight: Double
}
```

---

## HomeLoadState — unchanged

```swift
enum HomeLoadState: Equatable {
    case idle; case loading; case loaded(HomeScreenData); case failed(String)
}
```

---

## TodayViewModel — exercisesForToday now sorted

```swift
var exercisesForToday: [TodayExercise] {
    guard case .loaded(let d) = loadState else { return [] }
    return (d.exercisesForToday ?? []).sorted { $0.orderIndex < $1.orderIndex }
}
```

---

## TodayView UI mapping (additions)

| New data | UI location |
|----------|-------------|
| `WorkoutDayPlanSummary.dayOfWeek` | Small label below plan name in workout card (e.g., "SUNDAY") |
| `TodayExercise` sorted by `orderIndex` | Exercise list in ascending order |
| `TodayExerciseSet` sorted by `orderIndex` | Listed under each exercise: "Set N: Xreps × Ykg" |
