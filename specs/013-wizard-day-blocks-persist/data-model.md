# Data Model: Wizard Step 2 — Persist Day Plan with Exercise Blocks

**Date**: 2026-05-02

---

## New / Updated request types (Models/WorkoutDayPlanModels.swift)

### TargetSetRequest (NEW)

```swift
struct TargetSetRequest: Codable {
    let orderIndex: Int    // 1-based position in the block's set list
    let targetReps: Int
    let targetWeight: Double
}
```

### ExerciseBlockRequest (replaces ExerciseBlockPlanRequest)

```swift
struct ExerciseBlockRequest: Codable {
    let exerciseId: Int
    let orderIndex: Int       // 1-based position in the day's block list
    let restSeconds: Int
    let isOptional: Bool      // defaults to false
    let targetSets: [TargetSetRequest]

    init(block: ExerciseBlock, orderIndex: Int) {
        self.exerciseId = Int(block.exerciseId) ?? 0
        self.orderIndex = orderIndex
        self.restSeconds = block.restSeconds
        self.isOptional = false
        self.targetSets = [
            TargetSetRequest(orderIndex: 1,
                             targetReps: block.targetReps,
                             targetWeight: block.targetWeight)
        ]
    }
}
```

### WorkoutDayPlanRequest (UPDATED — adds exerciseBlocks)

```swift
struct WorkoutDayPlanRequest: Codable {
    let name: String
    let orderIndex: Int
    let isActive: Bool
    let exerciseBlocks: [ExerciseBlockRequest]
}
```

---

## Removed types

- `ExerciseBlockPlanRequest` — replaced by `ExerciseBlockRequest` (nested in day request)

---

## Protocol changes (WorkoutDayPlanServiceProtocol)

```swift
// BEFORE (feature 011):
func saveDayPlan(...) async throws -> WorkoutDayPlanResponse
func saveExerciseBlock(...) async throws

// AFTER (feature 013):
func saveDayPlan(workoutPlanId: Int, request: WorkoutDayPlanRequest) async throws
// saveExerciseBlock removed
```

---

## ViewModel change (NewPlanViewModel.saveDayConfig)

```swift
// BEFORE: two-step save
let dayResponse = try await service.saveDayPlan(...)    // step 1
for block in plan.blocks { try await service.saveExerciseBlock(...) }  // step 2

// AFTER: single unified POST
let request = WorkoutDayPlanRequest(
    name: plan.sessionName,
    orderIndex: day.orderIndex,
    isActive: true,
    exerciseBlocks: plan.blocks.enumerated().map { idx, block in
        ExerciseBlockRequest(block: block, orderIndex: idx + 1)
    }
)
try await service.saveDayPlan(workoutPlanId: planId, request: request)
```
