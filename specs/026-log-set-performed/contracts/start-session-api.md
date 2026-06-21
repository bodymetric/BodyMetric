# API Contract: POST /api/work-executions/start

**Updated**: 2026-06-13 (bug fix — `exerciseBlockExecutionId` is now documented as optional)

---

## Request

**Method**: `POST`  
**Path**: `/api/work-executions/start`  
**Auth**: Bearer token in `Authorization` header (Principle VII)

**Body**:
```json
{
  "planId": 201,
  "actualWeekNumber": 1,
  "feeling": "OK"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `planId` | `Int` | ✅ | ID of the workout plan to start |
| `actualWeekNumber` | `Int` | ✅ | Current week number for progression tracking |
| `feeling` | `String` | ✅ | Must be uppercase: `"LOW"`, `"OK"`, or `"HIGH"` |

---

## Response (200 OK)

```json
{
  "workExecutionId": 20,
  "workoutPlanId": 201,
  "workoutPlanName": "Plan Name",
  "totalNumberOfSets": 4,
  "exerciseBlockPlans": [
    {
      "exerciseBlockPlanId": 93,
      "exerciseBlockExecutionId": 301,
      "exerciseId": 113,
      "exerciseName": "Inverted Row",
      "orderIndex": 1,
      "restSeconds": 90,
      "isOptional": false,
      "numberOfSets": 4,
      "targetSets": [
        {
          "targetSetId": 193,
          "orderIndex": 1,
          "targetReps": 8,
          "targetWeight": 60.0
        }
      ]
    }
  ]
}
```

### Response Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `workExecutionId` | `Int` | ✅ | Unique ID of this workout execution session |
| `workoutPlanId` | `Int` | ✅ | Plan ID |
| `workoutPlanName` | `String` | ✅ | Display name |
| `totalNumberOfSets` | `Int` | ✅ | Total sets across all exercises |
| `exerciseBlockPlans` | `[ExerciseBlockPlan]` | ✅ | Ordered list of exercise blocks |

### ExerciseBlockPlan fields

| Field | Type | Required by server | Swift model type | Notes |
|-------|------|--------------------|------------------|-------|
| `exerciseBlockPlanId` | `Int` | ✅ | `Int` | Plan-level ID |
| `exerciseBlockExecutionId` | `Int` | ⚠️ Optional | `Int?` | **Execution-level ID — currently not returned by backend; app defaults to 0 when absent** |
| `exerciseId` | `Int` | ✅ | `Int` | |
| `exerciseName` | `String` | ✅ | `String` | |
| `orderIndex` | `Int` | ✅ | `Int` | Used to sort blocks |
| `restSeconds` | `Int` | ✅ | `Int` | |
| `isOptional` | `Bool` | ✅ | `Bool` | |
| `numberOfSets` | `Int` | ✅ | `Int` | |
| `targetSets` | `[TargetSet]` | ✅ | `[TargetSet]` | |

> **Note**: `exerciseBlockExecutionId` is marked Optional because the current backend does not include it. The Swift model (`ExerciseBlockPlan`) uses `Int?` to allow decoding to succeed. It is mapped to `WorkoutExercise.exerciseBlockExecutionId: Int` with `?? 0`. A value of `0` means the server did not provide it; the "Log set" action is guarded against this case. When the backend adds this field, the guard will become unreachable and the log-set flow will work end-to-end.

---

## Error Responses

| Status | Meaning |
|--------|---------|
| `400` | Invalid request body |
| `401` | Unauthorized (token expired or missing) |
| `404` | Plan not found |
| `5xx` | Server error |
