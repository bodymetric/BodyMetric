# Quickstart: Home Screen Workout Data — Corrected API Contract

**Date**: 2026-05-03

---

## Models/HomeModels.swift — full replacement

```swift
struct HomeScreenData: Decodable, Equatable {
    let currentWorkoutDayPlan: WorkoutDayPlanSummary?
    let exercisesForToday: [TodayExercise]?
}

struct WorkoutDayPlanSummary: Decodable, Equatable {
    let id: Int                          // NEW
    let name: String
    let dayOfWeek: String                // NEW (e.g., "SUNDAY")
    let numberOfExercisesTotal: Int
    let numberSetsTotal: Int
    let timeEstimateToFinish: Int        // RENAMED (was timeEstimateToFinishes)
}

struct TodayExercise: Decodable, Identifiable, Equatable {
    let id: Int
    let name: String
    let orderIndex: Int                  // NEW — sort by this
    let sets: [TodayExerciseSet]         // NEW
}

struct TodayExerciseSet: Decodable, Equatable {
    let orderIndex: Int                  // NEW — sort by this
    let targetReps: Int                  // NEW
    let targetWeight: Double             // NEW
}

enum HomeLoadState: Equatable { ... }   // unchanged
```

---

## TodayViewModel — exercisesForToday sorts by orderIndex

```swift
var exercisesForToday: [TodayExercise] {
    guard case .loaded(let d) = loadState else { return [] }
    return (d.exercisesForToday ?? []).sorted { $0.orderIndex < $1.orderIndex }
}
```

---

## TodayView — workout card additions

```swift
// In populatedWorkoutCard(_:)
Text(plan.dayOfWeek.capitalized)    // NEW — below plan name
    .font(.system(size: 13, design: .monospaced))
    .foregroundStyle(GrayscalePalette.background.opacity(0.65))

// Change timeEstimateToFinishes → timeEstimateToFinish:
StatBadge(value: "\(plan.timeEstimateToFinish)", label: "est. min")
```

---

## TodayView — exercises card shows sets

```swift
// In exercisesCard, under each exercise name, add:
ForEach(ex.sets.sorted { $0.orderIndex < $1.orderIndex }) { set in
    Text("Set \(set.orderIndex): \(set.targetReps) reps × \(formattedWeight(set.targetWeight))kg")
        .font(.system(size: 11, design: .monospaced))
        .foregroundStyle(GrayscalePalette.secondary)
}
```

---

## Test fixture updates

### HomeServiceTests.swift

```json
// Update mock JSON to include new fields:
{
  "currentWorkoutDayPlan": {
    "id": 7,
    "name": "Peito e Tríceps",
    "dayOfWeek": "SUNDAY",
    "numberOfExercisesTotal": 3,
    "numberSetsTotal": 9,
    "timeEstimateToFinish": 45
  },
  "exercisesForToday": [
    {
      "id": 1, "name": "Bench Press", "orderIndex": 1,
      "sets": [{"orderIndex": 1, "targetReps": 12, "targetWeight": 25.0}]
    }
  ]
}

// Update assertions:
XCTAssertEqual(result.currentWorkoutDayPlan?.timeEstimateToFinish, 45)  // was timeEstimateToFinishes
XCTAssertEqual(result.exercisesForToday?[0].sets[0].targetReps, 12)     // NEW
```

### TodayViewModelTests.swift

```swift
// Update WorkoutDayPlanSummary constructor calls:
WorkoutDayPlanSummary(id: 1, name: "Test", dayOfWeek: "MONDAY",
                      numberOfExercisesTotal: 5, numberSetsTotal: 15,
                      timeEstimateToFinish: 60)  // was timeEstimateToFinishes

// Update TodayExercise constructor calls:
TodayExercise(id: 0, name: "Exercise 0", orderIndex: 0,
              sets: [TodayExerciseSet(orderIndex: 1, targetReps: 10, targetWeight: 20)])
```
