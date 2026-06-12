# API Contract: Log Performed Set

**Feature**: `026-log-set-performed`  
**Date**: 2026-06-11

---

## POST /api/exercise-block-executions/{exerciseBlockExecutionId}/performed-sets

Records a single performed set for a specific exercise block execution within the current workout session.

### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `exerciseBlockExecutionId` | Int | Yes | The execution-level ID of the exercise block. Returned in `ExerciseBlockPlan.exerciseBlockExecutionId` from `POST /api/work-executions/start`. |

### Request Headers

| Header | Value |
|--------|-------|
| `Content-Type` | `application/json` |
| `Authorization` | `Bearer <id_token>` (attached by `NetworkClient`) |

### Request Body

```json
{
  "weight": 69.0,
  "reps": 5
}
```

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `weight` | Double | ≥ 0.0 | Weight lifted in kg. 0 is valid (bodyweight exercises). |
| `reps` | Int | ≥ 1 | Number of repetitions performed. Must be ≥ 1 (validated client-side). |

### Responses

| Status | Meaning | Response Body |
|--------|---------|---------------|
| 200 OK | Set logged successfully | Ignored |
| 201 Created | Set created successfully | Ignored |
| 400 Bad Request | Invalid request body | Error (not parsed) |
| 401 Unauthorized | Token invalid or expired | Triggers `TokenRefreshCoordinator` |
| 4xx / 5xx | Server or client error | `WorkoutPlanError.serverError(code)` |

### Error Handling

- Network failure → `WorkoutPlanError.networkError(URLError)`
- Non-200/201 status → `WorkoutPlanError.serverError(Int)`
- JSON encode failure → `WorkoutPlanError.networkError(error)`

### Example Request

```
POST https://api.bodymetric.com.br/api/exercise-block-executions/123/performed-sets

{
  "weight": 69,
  "reps": 5
}
```

---

## Updated: POST /api/work-executions/start — ExerciseBlockPlan shape

The start-session response is extended to include `exerciseBlockExecutionId` per exercise block.

```json
{
  "workExecutionId": 9,
  "workoutPlanId": 188,
  "workoutPlanName": "Push Day",
  "totalNumberOfSets": 4,
  "exerciseBlockPlans": [
    {
      "exerciseBlockPlanId": 72,
      "exerciseBlockExecutionId": 301,
      "exerciseId": 113,
      "exerciseName": "Inverted Row",
      "orderIndex": 1,
      "restSeconds": 90,
      "isOptional": false,
      "numberOfSets": 4,
      "targetSets": [
        {"targetSetId": 109, "orderIndex": 1, "targetReps": 8, "targetWeight": 60.0},
        {"targetSetId": 110, "orderIndex": 2, "targetReps": 8, "targetWeight": 60.0}
      ]
    }
  ]
}
```

New field: `exerciseBlockExecutionId: Int` — the ID used as the path param for `POST /api/exercise-block-executions/{id}/performed-sets`.
