# API Contracts: Start Workout Flow

**Branch**: `018-start-workout-flow`  
**Date**: 2026-05-18

---

## POST /api/work-executions/start

Starts a new workout execution session for the authenticated user.

### Request

```
POST https://api.bodymetric.com.br/api/work-executions/start
Authorization: Bearer <access_token>
Content-Type: application/json
```

### Request Body

```json
{
  "planId": 4,
  "actualWeekNumber": 1,
  "feeling": "OK"
}
```

**Field rules**:
- `planId`: Server-assigned ID of the active workout plan. Sourced from `WorkoutDayPlanSummary.id` (home screen data).
- `actualWeekNumber`: Current training week number. Sourced from `WorkoutDayPlanSummary.actualWeekNumber` (defaults to `1` if nil).
- `feeling`: User's selected feeling, **always uppercase** (`"LOW"`, `"OK"`, `"HIGH"`).

### Response — 200 OK / 201 Created

```json
{
  "id": "exec-abc123",
  "planId": 4,
  "actualWeekNumber": 1,
  "feeling": "OK",
  "exercises": [
    {
      "id": "ex-1",
      "name": "Bench Press",
      "muscle": "Chest",
      "restSeconds": 120,
      "sets": [
        { "targetReps": 8, "prevWeight": 80.0, "prevReps": 8 },
        { "targetReps": 8, "prevWeight": 80.0, "prevReps": 8 },
        { "targetReps": 6, "prevWeight": 80.0, "prevReps": 7 }
      ],
      "pr": { "weight": 82.5, "reps": 6 }
    },
    {
      "id": "ex-2",
      "name": "Incline Dumbbell Press",
      "muscle": "Upper Chest",
      "restSeconds": 90,
      "sets": [
        { "targetReps": 10, "prevWeight": 28.0, "prevReps": 10 }
      ],
      "pr": null
    }
  ]
}
```

**Client handling on success**: Map response to `WorkoutSession` via `StartSessionResponse.toWorkoutSession()` and navigate to `ActiveSessionView`.

### Response — 400 Bad Request

```json
{ "error": "Invalid plan or week number" }
```

**Client handling**: Display error message on Ready to Lift screen; re-enable "Begin session" button.

### Response — 401 Unauthorized

Handled automatically by `NetworkClient` (token refresh + retry).

### Response — 404 Not Found

Plan no longer exists.

**Client handling**: Display error message; user must return to home screen.

### Response — 5xx Server Error

**Client handling**: Display generic error message; re-enable "Begin session" button for retry.

---

## WorkoutExecutionServiceProtocol

```swift
@MainActor
protocol WorkoutExecutionServiceProtocol: AnyObject {
    /// Starts a new workout execution session.
    /// - Parameter request: Contains planId, actualWeekNumber, and uppercase feeling.
    /// - Returns: Session response with generated exercise blocks.
    /// - Throws: `WorkoutPlanError.serverError` for non-200/201,
    ///   `WorkoutPlanError.decodingError` for malformed response,
    ///   `WorkoutPlanError.networkError` for transport failures.
    func startSession(_ request: StartSessionRequest) async throws -> StartSessionResponse
}
```

---

## HomeModels Change

`WorkoutDayPlanSummary` gains `actualWeekNumber: Int?`.

The home screen API (`GET /api/home`) must include this field in the `currentWorkoutDayPlan` object:

```json
{
  "currentWorkoutDayPlan": {
    "id": 4,
    "name": "Chest Day",
    "dayOfWeek": "MONDAY",
    "numberOfExercisesTotal": 5,
    "numberSetsTotal": 15,
    "timeEstimateToFinish": 52,
    "actualWeekNumber": 3
  },
  ...
}
```

**Client handling for nil**: If `actualWeekNumber` is absent (null), client sends `1` in the session-start request.
