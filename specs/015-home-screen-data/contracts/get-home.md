# Contract: GET /api/home

**Endpoint**: `GET https://api.bodymetric.com.br/api/home`  
**Purpose**: Fetch all data needed to render the home screen in one request.

## Request

```
GET /api/home
Authorization: Bearer <access_token>
```

## Success Response — 200 OK

```json
{
  "currentWorkoutDayPlan": {
    "name": "Peito e Tríceps",
    "numberOfExercisesTotal": 1,
    "numberSetsTotal": 1,
    "timeEstimateToFinishes": 2
  },
  "exercisesForToday": [
    { "id": 26, "name": "Back Extension" }
  ]
}
```

Both `currentWorkoutDayPlan` and `exercisesForToday` are optional:
- `currentWorkoutDayPlan: null` or absent → show empty state
- `exercisesForToday: null`, absent, or `[]` → hide exercises card

## Mobile response handling

| Response | `loadState` | UI |
|----------|-------------|-----|
| 200 with plan | `.loaded(data)` | Populated workout card; exercises card if non-empty |
| 200 without plan | `.loaded(data)` | Empty state workout card; no exercises card |
| 401 | `NetworkClient` retries with refreshed token | — |
| Any other error | `.failed(message)` | Error banner on workout card area |
| Network error | `.failed(message)` | Error banner on workout card area |
