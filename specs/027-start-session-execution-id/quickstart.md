# Quickstart: Start Session Returns Exercise Block Execution ID

**Feature**: `027-start-session-execution-id`  
**Date**: 2026-06-21

---

## Scenario 1 — Session starts and all blocks have valid execution IDs (happy path)

**Given** the server returns `exerciseBlockPlans` with `exerciseBlockExecutionId` for each block:
```json
[
  { "exerciseBlockPlanId": 93, "exerciseBlockExecutionId": 456, "exerciseName": "Inverted Row", ... },
  { "exerciseBlockPlanId": 94, "exerciseBlockExecutionId": 457, "exerciseName": "Bench Press", ... }
]
```
**When** the user taps "Begin session"  
**Then** the active session screen opens; each `WorkoutExercise` in memory carries its own `exerciseBlockExecutionId` (456 and 457 respectively)

---

## Scenario 2 — Log set uses the correct execution ID for each block

**Given** the session started with block A having `exerciseBlockExecutionId: 456` and block B having `exerciseBlockExecutionId: 457`  
**When** the user taps "Log set" on block B  
**Then** the app calls `POST /api/exercise-block-executions/457/performed-sets` (not 456)  
**And** the set row for block B is marked done

---

## Scenario 3 — Session start fails when `exerciseBlockExecutionId` is missing from any block

**Given** the server returns a block without `exerciseBlockExecutionId`:
```json
{ "exerciseBlockPlanId": 93, "exerciseId": 113, "exerciseName": "Inverted Row", ... }
```
**When** the user taps "Begin session"  
**Then** the app shows an error message on the check-in screen ("Could not read the server response.")  
**And** the user remains on the check-in screen with mood and warm-up selections intact

---

## Scenario 4 — Log set guarded against server sending 0 as execution ID

**Given** a session block somehow has `exerciseBlockExecutionId: 0` (abnormal server value)  
**When** the user taps "Log set"  
**Then** an error is shown: "Cannot log set: invalid session data."  
**And** no network request is sent to the API

---

## Scenario 5 — Multiple blocks log sets independently

**Given** a session with 3 exercise blocks having execution IDs 456, 457, 458  
**When** the user logs sets on blocks 3, 1, 2 (out of order)  
**Then** each "Log set" request uses the correct ID for that specific block (458, 456, 457 respectively)  
**And** no ID cross-contamination occurs

---

## Test Fixture (for unit tests)

```json
{
  "workExecutionId": 9,
  "workoutPlanId": 201,
  "workoutPlanName": "Push Day",
  "totalNumberOfSets": 4,
  "exerciseBlockPlans": [
    {
      "exerciseBlockPlanId": 72,
      "exerciseBlockExecutionId": 301,
      "exerciseId": 113,
      "exerciseName": "Bench Press",
      "orderIndex": 1,
      "restSeconds": 90,
      "isOptional": false,
      "numberOfSets": 2,
      "targetSets": [
        { "targetSetId": 1, "orderIndex": 1, "targetReps": 8, "targetWeight": 80.0 },
        { "targetSetId": 2, "orderIndex": 2, "targetReps": 8, "targetWeight": 80.0 }
      ]
    }
  ]
}
```
