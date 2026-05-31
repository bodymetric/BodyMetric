# Contract: POST /api/workout-plans/{workoutPlanId}/days

**Endpoint**: `POST https://api.bodymetric.com.br/api/workout-plans/{workoutPlanId}/days`  
**Purpose**: Create one training day with its exercise blocks and target sets in a single operation.

## Request body

```json
{
  "name": "Chest and Triceps",
  "orderIndex": 1,
  "isActive": true,
  "exerciseBlocks": [
    {
      "exerciseId": 1,
      "orderIndex": 1,
      "restSeconds": 60,
      "isOptional": false,
      "targetSets": [
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

## Field derivation

| JSON field | Source |
|------------|--------|
| `name` | `DayPlan.sessionName` |
| `orderIndex` (day) | `DayOfWeek.rawValue - 1` (Mon=0, Sun=6) |
| `isActive` | Always `true` |
| `exerciseBlocks[n].exerciseId` | `Int(ExerciseBlock.exerciseId) ?? 0` |
| `exerciseBlocks[n].orderIndex` | 1-based position in `plan.blocks` |
| `exerciseBlocks[n].restSeconds` | `ExerciseBlock.restSeconds` |
| `exerciseBlocks[n].isOptional` | Always `false` (v1) |
| `targetSets[0].orderIndex` | Always `1` (single-set UI) |
| `targetSets[0].targetReps` | `ExerciseBlock.targetReps` |
| `targetSets[0].targetWeight` | `ExerciseBlock.targetWeight` |

## Success Responses

| Status | Action |
|--------|--------|
| 201 Created | Save succeeded; advance wizard |
| 200 OK | Save succeeded; advance wizard |

## Error Responses

| Status | Action |
|--------|--------|
| 400 | `dayConfigSaveError` shown; user stays on screen |
| 401 | `NetworkClient` retries with refreshed token |
| 500+ | `dayConfigSaveError` shown; user stays on screen |
