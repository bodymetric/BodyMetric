# Quickstart: Wizard Step 2 — Persist Day Plan with Exercise Blocks

**Date**: 2026-05-02

---

## Models/WorkoutDayPlanModels.swift — full replacement

```swift
// NEW
struct TargetSetRequest: Codable {
    let orderIndex: Int
    let targetReps: Int
    let targetWeight: Double
}

// REPLACES ExerciseBlockPlanRequest
struct ExerciseBlockRequest: Codable {
    let exerciseId: Int
    let orderIndex: Int
    let restSeconds: Int
    let isOptional: Bool
    let targetSets: [TargetSetRequest]

    init(block: ExerciseBlock, orderIndex: Int) {
        self.exerciseId  = Int(block.exerciseId) ?? 0
        self.orderIndex  = orderIndex
        self.restSeconds = block.restSeconds
        self.isOptional  = false
        self.targetSets  = [TargetSetRequest(orderIndex: 1,
                                             targetReps: block.targetReps,
                                             targetWeight: block.targetWeight)]
    }
}

// UPDATED — adds exerciseBlocks
struct WorkoutDayPlanRequest: Codable {
    let name: String
    let orderIndex: Int
    let isActive: Bool
    let exerciseBlocks: [ExerciseBlockRequest]
}

// KEPT (server may return this; not consumed by client in v1)
struct WorkoutDayPlanResponse: Decodable, Identifiable {
    let workoutDayPlanId: Int
    var id: Int { workoutDayPlanId }
}
```

---

## WorkoutDayPlanServiceProtocol.swift

```swift
// REMOVE saveExerciseBlock
// UPDATE saveDayPlan to return Void (workoutDayPlanId no longer needed):
func saveDayPlan(workoutPlanId: Int, request: WorkoutDayPlanRequest) async throws
```

---

## WorkoutDayPlanService.swift

```swift
func saveDayPlan(workoutPlanId: Int, request: WorkoutDayPlanRequest) async throws {
    // ... build URLRequest, POST ...
    // CHANGE: accept 200 or 201
    guard [200, 201].contains(http.statusCode) else {
        throw WorkoutPlanError.serverError(http.statusCode)
    }
    // No decode needed (response body not consumed)
}
// DELETE saveExerciseBlock method
```

---

## NewPlanViewModel.saveDayConfig

```swift
func saveDayConfig(
    for day: DayOfWeek,
    using service: any WorkoutDayPlanServiceProtocol,
    onSuccess: @MainActor @Sendable () -> Void
) async {
    guard !isDayConfigSaving,
          let plan = dayPlans[day],
          let planId = workoutPlanIds[day] else { return }

    isDayConfigSaving = true
    dayConfigSaveError = nil
    Logger.info("wizard_day_config_save_started day:\(day.shortLabel)")

    do {
        let request = WorkoutDayPlanRequest(
            name: plan.sessionName,
            orderIndex: day.orderIndex,
            isActive: true,
            exerciseBlocks: plan.blocks.enumerated().map { idx, block in
                ExerciseBlockRequest(block: block, orderIndex: idx + 1)
            }
        )
        try await service.saveDayPlan(workoutPlanId: planId, request: request)
        Logger.info("wizard_day_plan_saved day:\(day.shortLabel) blockCount:\(plan.blocks.count)")
        onSuccess()
    } catch {
        Logger.error("wizard_day_config_save_failed", error: error)
        dayConfigSaveError = "Could not save your workout day. Please try again."
    }
    isDayConfigSaving = false
}
```

---

## Trace events (unchanged)

| Event | When |
|-------|------|
| `wizard_day_config_save_started` | `saveDayConfig` begins |
| `wizard_day_plan_saved` | POST 200/201 |
| `wizard_day_config_save_failed` | Any error |
