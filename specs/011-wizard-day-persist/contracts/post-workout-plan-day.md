# Contract: POST /api/workout-plans/{workoutPlanId}/days

**Feature**: `011-wizard-day-persist`  
**Endpoint**: `POST https://api.bodymetric.com.br/api/workout-plans/{workoutPlanId}/days`  
**Purpose**: Create a named training day within the authenticated user's workout plan.

## Path parameter

| Parameter | Type | Source |
|-----------|------|--------|
| `workoutPlanId` | Int | `planId` from the step 1 response (`WorkoutPlanDayResponse.planId`) for the corresponding `DayOfWeek` |

## Request

```
POST /api/workout-plans/{workoutPlanId}/days
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "name": "Peito e Tríceps",
  "orderIndex": 6,
  "isActive": true
}
```

| Field | Type | Constraint |
|-------|------|-----------|
| `name` | String | Non-empty; session name entered by user |
| `orderIndex` | Int | 0-based (Mon=0, Sun=6); derived as `day.rawValue - 1` |
| `isActive` | Bool | Always `true` for wizard-created days |

## Success Response — 201 Created

Returns the newly created day plan. The app requires `workoutDayPlanId` to POST exercise blocks.

```json
{
  "workoutDayPlanId": 42,
  ...
}
```

## Error Responses

| Status | Meaning | App behaviour |
|--------|---------|---------------|
| 401 | Token expired | NetworkClient retries once with refreshed token |
| 400 | Invalid request body | `dayConfigSaveError` set; user stays on step 2 |
| 404 | workoutPlanId not found | `dayConfigSaveError` set; user stays on step 2 |
| 500+ | Server error | `dayConfigSaveError` set; user stays on step 2 |

## Mobile response handling

| Response | Action |
|----------|--------|
| 201 | Decode `workoutDayPlanId`; proceed to POST exercise blocks |
| Any non-201 | Stop immediately; set `dayConfigSaveError`; keep user on step 2 |
