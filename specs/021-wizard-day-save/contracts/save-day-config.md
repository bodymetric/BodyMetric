# API Contract: POST /api/workout-plans/{workoutPlanId}/days

**Feature**: 021-wizard-day-save
**Endpoint**: `POST https://api.bodymetric.com.br/api/workout-plans/{workoutPlanId}/days`
**Auth**: Bearer token required (`Authorization: Bearer <id_token>`)
**Trigger**: User taps Continue on wizard step 2 (create mode only; edit mode uses a different endpoint)

---

## Request

### URL Parameter

| Parameter | Type | Required | Notes |
|-----------|------|----------|-------|
| workoutPlanId | Int | yes | Server-assigned plan ID from step 1's `saveDays` response |

### Request Body (JSON)

```json
{
  "name": "Peito e Tríceps",
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

### Request Fields

#### Top-level

| Field | Type | Source | Notes |
|-------|------|--------|-------|
| name | String | `DayPlan.sessionName` | User-entered session name on screen |
| orderIndex | Int | `DayOfWeek.orderIndex` | 0-based weekday index (Mon=0, Sun=6) |
| isActive | Bool | constant `true` | Always true; no UI toggle in scope |
| exerciseBlocks | Array | `DayPlan.blocks` | All exercise blocks on the screen |

#### Each exerciseBlock

| Field | Type | Source | Notes |
|-------|------|--------|-------|
| exerciseId | Int | `ExerciseBlock.exerciseId` (parsed as Int) | Server exercise catalog ID |
| orderIndex | Int | block position | 1-based index in the block list |
| restSeconds | Int | `ExerciseBlock.restSeconds` | Block-level rest time in seconds |
| isOptional | Bool | constant `false` | Always false; no UI toggle in scope |
| targetSets | Array | `ExerciseBlock.sets` | Per-set configuration |

#### Each targetSet

| Field | Type | Source | Notes |
|-------|------|--------|-------|
| orderIndex | Int | set position | 1-based index in the set list |
| targetReps | Int | `SetConfig.targetReps` | Target rep count for this set |
| targetWeight | Double | `SetConfig.targetWeight` | Target weight in kg |

---

## Response

### Success

| Status | Body | Meaning |
|--------|------|---------|
| 200 OK | any / empty | Day saved |
| 201 Created | any / empty | Day created |

Response body is not consumed by the client. Both 200 and 201 advance the wizard.

### Errors

| Status | Client behaviour |
|--------|-----------------|
| 4xx | `dayConfigSaveError` set; wizard stays on step 2 |
| 5xx | `dayConfigSaveError` set; wizard stays on step 2 |
| Network failure | `dayConfigSaveError` set; wizard stays on step 2 |

Error message shown to user: `"Could not save your workout day. Please try again."`

---

## Client Model Mapping

```swift
// Models/WorkoutDayPlanModels.swift

struct WorkoutDayPlanRequest: Codable {
    let name: String
    let orderIndex: Int
    let isActive: Bool
    let exerciseBlocks: [ExerciseBlockRequest]
}

struct ExerciseBlockRequest: Codable {
    let exerciseId: Int
    let orderIndex: Int
    let restSeconds: Int
    let isOptional: Bool
    let targetSets: [TargetSetRequest]
}

struct TargetSetRequest: Codable {
    let orderIndex: Int
    let targetReps: Int
    let targetWeight: Double
}
```
