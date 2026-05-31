# API Contracts: Edit Existing Workout Plan

**Branch**: `017-edit-workout-plan`  
**Date**: 2026-05-17

---

## GET /api/workout-plans/current

Fetches the authenticated user's current active workout plan with all nested day plans and exercise blocks.

### Request

```
GET https://api.bodymetric.com.br/api/workout-plans/current
Authorization: Bearer <access_token>
```

### Response — 200 OK

```json
{
  "id": 123,
  "days": [
    {
      "id": 456,
      "plannedDayOfWeek": "MONDAY",
      "name": "Chest Day",
      "orderIndex": 0,
      "exerciseBlocks": [
        {
          "exerciseId": 26,
          "orderIndex": 1,
          "restSeconds": 90,
          "targetSets": [
            {
              "orderIndex": 1,
              "targetReps": 10,
              "targetWeight": 60.0
            }
          ]
        }
      ]
    },
    {
      "id": 457,
      "plannedDayOfWeek": "WEDNESDAY",
      "name": "Leg Day",
      "orderIndex": 2,
      "exerciseBlocks": [
        {
          "exerciseId": 4,
          "orderIndex": 1,
          "restSeconds": 120,
          "targetSets": [
            {
              "orderIndex": 1,
              "targetReps": 8,
              "targetWeight": 80.0
            }
          ]
        }
      ]
    }
  ]
}
```

### Response — 404 Not Found

Returned when the authenticated user has no current active plan.

```json
{ "error": "No active workout plan found" }
```

**Client handling**: Treat 404 as "no plan" — the app should not show an error but should keep "My Plan" hidden.

### Response — 401 Unauthorized

The `NetworkClient` intercepts this, refreshes the token, and retries automatically. The service layer never sees a 401 except on refresh failure.

---

## PUT /api/workout-plans/{id}

Updates an existing workout plan with the full updated payload. Preserves the plan's server-assigned ID.

### Request

```
PUT https://api.bodymetric.com.br/api/workout-plans/{id}
Authorization: Bearer <access_token>
Content-Type: application/json
```

### Request Body

```json
{
  "days": [
    {
      "plannedDayOfWeek": "monday",
      "name": "Chest Day",
      "orderIndex": 0,
      "isActive": true,
      "exerciseBlocks": [
        {
          "exerciseId": 26,
          "orderIndex": 1,
          "restSeconds": 90,
          "isOptional": false,
          "targetSets": [
            {
              "orderIndex": 1,
              "targetReps": 12,
              "targetWeight": 65.0
            }
          ]
        }
      ]
    }
  ]
}
```

**Notes**:
- `plannedDayOfWeek` is lowercase (matching existing `WorkoutPlanDayRequest.plannedDayOfWeek` format: `fullLabel.lowercased()`).
- `orderIndex` on the day uses `DayOfWeek.orderIndex` (Mon=0, Sun=6).
- Only the days currently selected in the wizard are included; days removed by the user are omitted from the payload.
- `isOptional` on exercise blocks is always `false` in v1.
- `targetSets` contains exactly one set per block in v1 (the wizard models one prescription per exercise).

### Response — 200 OK

```json
{ "id": 123 }
```

**Client handling**: On success, dismiss the wizard and return to home. The home screen reloads its data via `TodayViewModel.reload(using:)` to reflect the updated plan.

### Response — 400 Bad Request

```json
{ "error": "Invalid plan data" }
```

**Client handling**: Show error with retry option on the wizard review step.

### Response — 401 Unauthorized

Handled automatically by `NetworkClient`.

### Response — 404 Not Found

Returned if the plan ID no longer exists.

**Client handling**: Log error, show error state, allow user to dismiss and create a new plan.

---

## WorkoutPlanServiceProtocol — new methods

```swift
@MainActor
protocol WorkoutPlanServiceProtocol: AnyObject {
    // Existing
    func fetchDays() async throws -> [WorkoutPlanDayResponse]
    func saveDays(_ days: [WorkoutPlanDayRequest]) async throws -> [WorkoutPlanDayResponse]

    // New
    func fetchCurrentPlan() async throws -> CurrentWorkoutPlan
    func updatePlan(id: Int, request: UpdateWorkoutPlanRequest) async throws
}
```

### `fetchCurrentPlan()` errors

| Condition | Error thrown |
|-----------|-------------|
| 404 | `WorkoutPlanError.notFound` |
| 5xx | `WorkoutPlanError.serverError(statusCode)` |
| Decode failure | `WorkoutPlanError.decodingError` |
| Network failure | `WorkoutPlanError.networkError(underlying)` |

### `updatePlan(id:request:)` errors

| Condition | Error thrown |
|-----------|-------------|
| 400 / 404 | `WorkoutPlanError.serverError(statusCode)` |
| 5xx | `WorkoutPlanError.serverError(statusCode)` |
| Encode failure | `WorkoutPlanError.networkError(underlying)` |
| Network failure | `WorkoutPlanError.networkError(underlying)` |
