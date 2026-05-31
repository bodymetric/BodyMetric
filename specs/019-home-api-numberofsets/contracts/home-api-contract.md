# API Contract: GET /api/home

**Feature**: 019-home-api-numberofsets  
**Method**: GET  
**Path**: `/api/home`  
**Query param**: `currentDayOfWeek={DAY}` (e.g., `MONDAY`)  
**Auth**: Bearer token (injected by NetworkClient)

## Response Shape

```json
{
  "currentWorkoutDayPlan": {
    "id": 154,
    "name": "Chest and Triceps",
    "dayOfWeek": "MONDAY",
    "numberOfExercisesTotal": 4,
    "numberSetsTotal": 12,
    "timeEstimateToFinish": 45
  },
  "exercisesForToday": [
    {
      "id": 44,
      "name": "Dumbbell Curl",
      "orderIndex": 1,
      "numberOfSets": 3
    },
    {
      "id": 45,
      "name": "Barbell Bench Press",
      "orderIndex": 2,
      "numberOfSets": 4
    }
  ]
}
```

## Field Definitions

### currentWorkoutDayPlan

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | integer | yes | Unique identifier for the workout day plan |
| name | string | yes | Display name, e.g., "Chest and Triceps" |
| dayOfWeek | string | yes | UPPERCASE day, e.g., "MONDAY" |
| numberOfExercisesTotal | integer | yes | Count of exercises for this day |
| numberSetsTotal | integer | yes | Sum of all sets across all exercises |
| timeEstimateToFinish | integer | yes | Estimated duration in minutes |

### exercisesForToday items

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | integer | yes | Unique identifier for the exercise |
| name | string | yes | Display name, e.g., "Dumbbell Curl" |
| orderIndex | integer | yes | 1-based sort order for display |
| numberOfSets | integer | yes | Total configured sets for this exercise |

## Removed Fields

The following fields **MUST NOT** appear in the response:

- `targetSets` — previously an array of set prescriptions per exercise; replaced by the scalar `numberOfSets`

## Null / Empty States

| Scenario | Response |
|----------|----------|
| User has no workout plan | `currentWorkoutDayPlan: null`, `exercisesForToday: []` |
| Day has no exercises | `exercisesForToday: []` |

## HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success with data |
| 400 | Bad request (missing/invalid `currentDayOfWeek`) — client treats as no-plan state |
| 401 | Unauthorized — token expired; NetworkClient triggers refresh |
| 404 | No plan for user — client treats as no-plan state |

## Client Decoding Contract (iOS)

```swift
struct HomeScreenData: Decodable {
    let currentWorkoutDayPlan: WorkoutDayPlanSummary?
    let exercisesForToday: [TodayExercise]?
}

struct WorkoutDayPlanSummary: Decodable {
    let id: Int
    let name: String
    let dayOfWeek: String
    let numberOfExercisesTotal: Int
    let numberSetsTotal: Int
    let timeEstimateToFinish: Int
    let actualWeekNumber: Int?
}

struct TodayExercise: Decodable, Identifiable {
    let id: Int
    let name: String
    let orderIndex: Int
    let numberOfSets: Int
    // NO sets: [TodayExerciseSet]
}
// TodayExerciseSet is DELETED
```
