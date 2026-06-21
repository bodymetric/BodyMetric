# API Contract: POST /api/work-executions/start

**Updated**: 2026-06-21 (exerciseBlockExecutionId is now REQUIRED in response)

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
  "workoutPlanName": "Push Day",
  "totalNumberOfSets": 4,
  "exerciseBlockPlans": [
    {
      "exerciseBlockPlanId": 93,
      "exerciseBlockExecutionId": 456,
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

| Field | Type | Required | Swift model type | Notes |
|-------|------|----------|------------------|-------|
| `exerciseBlockPlanId` | `Int` | ✅ | `Int` | Plan-level ID |
| `exerciseBlockExecutionId` | `Int` | ✅ | `Int` | **REQUIRED** — Execution-level ID created when this session starts. Used for `POST /api/exercise-block-executions/{id}/performed-sets`. |
| `exerciseId` | `Int` | ✅ | `Int` | |
| `exerciseName` | `String` | ✅ | `String` | |
| `orderIndex` | `Int` | ✅ | `Int` | Used to sort blocks |
| `restSeconds` | `Int` | ✅ | `Int` | |
| `isOptional` | `Bool` | ✅ | `Bool` | |
| `numberOfSets` | `Int` | ✅ | `Int` | |
| `targetSets` | `[TargetSet]` | ✅ | `[TargetSet]` | |

> **Breaking change from 026 bug-fix**: `exerciseBlockExecutionId` was previously optional in the Swift model (`Int?`). It is now required (`Int`). If the server omits this field, the app will fail to decode the response and show an error on the check-in screen (by design — a session without execution IDs cannot log performed sets).

---

## Downstream API

The `exerciseBlockExecutionId` is used immediately after session start:

```
POST /api/exercise-block-executions/{exerciseBlockExecutionId}/performed-sets

Body: { "weight": 69.0, "reps": 5 }
```

---

## Error Responses

| Status | Meaning |
|--------|---------|
| `400` | Invalid request body |
| `401` | Unauthorized (token expired or missing) |
| `404` | Plan not found |
| `5xx` | Server error |
