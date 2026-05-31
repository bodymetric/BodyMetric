# Contract: GET /api/home (corrected)

**Endpoint**: `GET https://api.bodymetric.com.br/api/home`

## Success Response — 200 OK

```json
{
  "currentWorkoutDayPlan": {
    "id": 7,
    "name": "Peito e Tríceps",
    "dayOfWeek": "SUNDAY",
    "numberOfExercisesTotal": 1,
    "numberSetsTotal": 1,
    "timeEstimateToFinish": 2
  },
  "exercisesForToday": [
    {
      "id": 2,
      "name": "Bench Press",
      "orderIndex": 1,
      "sets": [
        {
          "orderIndex": 1,
          "targetReps": 12,
          "targetWeight": 25.0
        }
      ]
    }
  ]
}
```

## Field corrections vs feature 015

| JSON key | 015 (wrong) | 016 (correct) |
|----------|-------------|---------------|
| `timeEstimateToFinish` | `timeEstimateToFinishes` | `timeEstimateToFinish` |
| `currentWorkoutDayPlan.id` | missing | present |
| `currentWorkoutDayPlan.dayOfWeek` | missing | present |
| `exercisesForToday[n].orderIndex` | missing | present |
| `exercisesForToday[n].sets` | missing | present |

## Error handling (all unchanged from feature 015 / NetworkClient)

| Status | Behaviour |
|--------|-----------|
| 200 | Decode and render |
| 400/404 | Treat as empty home data (no error shown) |
| 401 | `NetworkClient` refreshes token and retries once; forced logout on second 401 |
| Other 4xx/5xx | `HomeLoadState.failed` → error banner + retry |
