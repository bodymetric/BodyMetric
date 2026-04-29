# Contract: POST /api/workout-day-plans/{workoutDayPlanId}/exercise-blocks

**Feature**: `011-wizard-day-persist`  
**Endpoint**: `POST https://api.bodymetric.com.br/api/workout-day-plans/{workoutDayPlanId}/exercise-blocks`  
**Purpose**: Add one exercise block to a training day in the user's workout plan.

## Path parameter

| Parameter | Type | Source |
|-----------|------|--------|
| `workoutDayPlanId` | Int | `workoutDayPlanId` from the `POST /days` response |

## Request

```
POST /api/workout-day-plans/{workoutDayPlanId}/exercise-blocks
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "exerciseId": "bench",
  "targetReps": 8,
  "targetWeightKg": 60.0,
  "restSeconds": 90
}
```

> ⚠️ **Field names assumed** — verify against live API. Adjust `ExerciseBlockPlanRequest.CodingKeys` if needed.

| Field | Type | Source | Notes |
|-------|------|--------|-------|
| `exerciseId` | String | `ExerciseBlock.exerciseId` | Catalog exercise identifier |
| `targetReps` | Int | `ExerciseBlock.targetReps` | Min 1 |
| `targetWeightKg` | Double | `ExerciseBlock.targetWeight` | 0 allowed (bodyweight) |
| `restSeconds` | Int | `ExerciseBlock.restSeconds` | 0 allowed |

This endpoint is called once per `ExerciseBlock` in `DayPlan.blocks`, sequentially.

## Success Response — 201 Created

Response body is not consumed by the app. Only the status code (201) is checked.

## Error Responses

| Status | Meaning | App behaviour |
|--------|---------|---------------|
| 401 | Token expired | NetworkClient retries once |
| 400 | Invalid block data | Stop sequence; set `dayConfigSaveError` |
| 404 | workoutDayPlanId not found | Stop sequence; set `dayConfigSaveError` |
| 500+ | Server error | Stop sequence; set `dayConfigSaveError` |

## Mobile response handling

| Response | Action |
|----------|--------|
| 201 | Continue to next block (or advance wizard if last block) |
| Any non-201 | Stop sequence; set `dayConfigSaveError`; keep user on step 2 |
