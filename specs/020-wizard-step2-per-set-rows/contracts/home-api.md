# API Contract: GET /api/home

**Feature**: Home screen data (amendment — 2026-05-28)  
**Endpoint**: `GET https://api.bodymetric.com.br/api/home?currentDayOfWeek={DAY}`  
**Auth**: Bearer token required (`Authorization: Bearer <id_token>`)

---

## Request

| Parameter | In | Type | Required | Notes |
|-----------|----|------|----------|-------|
| currentDayOfWeek | query | String | yes | Uppercase weekday name (e.g., `MONDAY`, `FRIDAY`) |

---

## Response — 200 OK

```json
{
  "currentWorkoutDayPlan": {
    "id": 153,
    "name": "Workout Name",
    "dayOfWeek": "FRIDAY",
    "numberOfExercisesTotal": 1,
    "numberSetsTotal": 0,
    "timeEstimateToFinish": 0
  },
  "exercisesForToday": [
    {
      "id": 43,
      "name": "Deadlift",
      "orderIndex": 1,
      "sets": []
    }
  ]
}
```

### currentWorkoutDayPlan (nullable)

| Field | Type | Notes |
|-------|------|-------|
| id | Int | server-assigned plan ID |
| name | String | user-defined workout name |
| dayOfWeek | String | uppercase weekday name (e.g., "FRIDAY") |
| numberOfExercisesTotal | Int | exercise count in the day plan |
| numberSetsTotal | Int | total sets across all exercises |
| timeEstimateToFinish | Int | estimated duration in minutes |

`currentWorkoutDayPlan` may be `null` when no plan exists for the user.

### exercisesForToday (nullable array)

Each element in `exercisesForToday`:

| Field | Type | Notes |
|-------|------|-------|
| id | Int | server-assigned exercise record ID |
| name | String | exercise name |
| orderIndex | Int | 1-based display order |
| sets | Array | may be empty `[]`; see set object below |

Each element in `sets`:

| Field | Type | Notes |
|-------|------|-------|
| orderIndex | Int | 1-based set position |
| targetReps | Int | target rep count |
| targetWeight | Double | target weight in kg |

---

## Error Responses

| Status | Meaning | Client behaviour |
|--------|---------|-----------------|
| 400 | No plan / bad day param | Treated as empty home data (no error shown) |
| 404 | No plan found | Treated as empty home data (no error shown) |
| 401 | Token expired | Token refresh flow triggered |
| 500 | Server error | `home_data_load_failed` logged; error banner shown |

---

## Client Model Mapping

```swift
// HomeModels.swift

struct HomeExerciseSet: Decodable, Equatable {
    let orderIndex: Int
    let targetReps: Int
    let targetWeight: Double
}

struct TodayExercise: Decodable, Identifiable, Equatable {
    let id: Int
    let name: String
    let orderIndex: Int
    let sets: [HomeExerciseSet]         // decoded from "sets" key
    var numberOfSets: Int { sets.count } // computed; NOT decoded from JSON
}
```

---

## Key Invariants

- `sets` is always present (may be empty array `[]`); it is never null
- `currentWorkoutDayPlan` may be null/absent; `exercisesForToday` may be null/absent
- `dayOfWeek` uses uppercase string ("MONDAY", "FRIDAY", etc.)
- `numberOfSets` is **not** a JSON field — it is computed from `sets.count` on the client
