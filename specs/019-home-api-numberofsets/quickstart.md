# Quickstart: Home API — Replace targetSets with numberOfSets

**Branch**: `019-home-api-numberofsets` | **Date**: 2026-05-24

## Integration Scenarios

### Scenario 1 — Home screen loads with today's exercises showing set count

**Setup**: Mock `HomeServiceProtocol` returns a `HomeScreenData` with 2 exercises, each with `numberOfSets: 3`.

**Steps**:
1. Present `TodayView` with the mock service.
2. Wait for data to load.

**Expected**:
- Workout card shows `numberSetsTotal` (e.g., "6 sets").
- Each exercise row shows `numberOfSets` (e.g., "3 sets" per exercise).
- No crash or decoding error.

**Mock fixture**:
```swift
HomeScreenData(
    currentWorkoutDayPlan: WorkoutDayPlanSummary(
        id: 1, name: "Chest Day", dayOfWeek: "MONDAY",
        numberOfExercisesTotal: 2, numberSetsTotal: 6,
        timeEstimateToFinish: 40, actualWeekNumber: 1
    ),
    exercisesForToday: [
        TodayExercise(id: 10, name: "Bench Press", orderIndex: 1, numberOfSets: 3),
        TodayExercise(id: 11, name: "Cable Fly",   orderIndex: 2, numberOfSets: 3)
    ]
)
```

---

### Scenario 2 — Home screen decodes server response with numberOfSets (no targetSets)

**Setup**: `MockNetworkClient` returns JSON matching the new contract.

**Steps**:
1. Call `HomeService.fetchHomeData()`.
2. Assert decoded model fields.

**Expected**:
- `result.exercisesForToday![0].numberOfSets == 3`
- `result.currentWorkoutDayPlan!.numberSetsTotal == 12`
- No `DecodingError` thrown.

**JSON fixture**:
```json
{
  "currentWorkoutDayPlan": {
    "id": 154, "name": "Chest and Triceps", "dayOfWeek": "MONDAY",
    "numberOfExercisesTotal": 4, "numberSetsTotal": 12, "timeEstimateToFinish": 45
  },
  "exercisesForToday": [
    { "id": 44, "name": "Dumbbell Curl", "orderIndex": 1, "numberOfSets": 3 }
  ]
}
```

---

### Scenario 3 — Build passes with zero targetSets references in home pipeline

**Setup**: After all changes, run the build.

**Expected**: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` exits with `BUILD SUCCEEDED`. No errors mentioning `TodayExerciseSet` or `sets:`.

---

### Scenario 4 — Empty exercisesForToday does not crash

**Setup**: Mock returns `exercisesForToday: []`.

**Expected**: TodayView renders an empty exercise list without crashing. `numberSetsTotal == 0` is displayed correctly (or gracefully hidden).
