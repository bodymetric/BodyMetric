# Contract: GET /api/workout-plans

**Feature**: `008-wizard-day-selection`  
**Endpoint**: `GET https://api.bodymetric.com.br/api/workout-plans`  
**Purpose**: Fetch the authenticated user's previously saved weekly training days.

## Request

```
GET /api/workout-plans
Authorization: Bearer <access_token>
```

No query parameters. No request body.

## Success Response — 200 OK

Returns an array of workout plan day entries. The array may be empty `[]` if the user has saved no days yet (though in practice the API returns 404 for that case — see below).

```json
[
  {
    "planId": 7,
    "plannedWeekNumber": 7,
    "plannedDayOfWeek": "sunday",
    "executionCount": 0,
    "dayNames": ["Costa e bíceps"],
    "totalExercises": 0,
    "totalSets": 0,
    "estimatedDurationMinutes": 0,
    "_links": {
      "self": {
        "href": "/api/workout-plans/7",
        "method": "GET"
      }
    }
  }
]
```

## "No prior data" Response — 404 Not Found

Indicates the user has never completed this wizard step. The app MUST treat this as an empty state (all days unchecked), NOT as an error. No error banner is shown.

## Error Responses

| Status | Meaning | App behaviour |
|--------|---------|---------------|
| 401 | Expired/invalid token | `NetworkClient` retries with refreshed token automatically; if retry also 401, user is signed out |
| 500+ | Server error | Load state = `failed`; screen shows empty form |

## Mobile app response handling

| Response | `SelectDaysLoadState` | UI |
|----------|----------------------|-----|
| 200 with items | `.loaded` | Days matching `plannedWeekNumber` are pre-checked |
| 200 empty array | `.empty` | All days unchecked, no error |
| 404 | `.empty` | All days unchecked, no error |
| Any other | `.failed(message)` | All days unchecked, no error banner |
