# Quickstart: Workout Plan Wizard — Step 2 Day & Exercise Persistence

**Feature**: `011-wizard-day-persist`  
**Date**: 2026-04-29

---

## What This Feature Adds

1. **`WorkoutDayPlanService`** — new service: POST day plan + POST exercise blocks
2. **`WorkoutDayPlanModels`** — new request/response DTOs
3. **`NewPlanViewModel` extensions** — `workoutPlanIds` map, `saveDayConfig()` method, step 2 save state
4. **Wizard wiring** — step 2 Continue triggers async save; error banner in `ConfigureDayStepView`
5. **Backward-compatible change** — `WorkoutPlanService.saveDays` now decodes and returns 201 response body

---

## New Files

| File | Purpose |
|------|---------|
| `Services/WorkoutPlan/WorkoutDayPlanService.swift` | Concrete service: POST `/days` + POST `/exercise-blocks` |
| `Services/WorkoutPlan/WorkoutDayPlanServiceProtocol.swift` | Protocol for testability |
| `Models/WorkoutDayPlanModels.swift` | `WorkoutDayPlanRequest`, `WorkoutDayPlanResponse`, `ExerciseBlockPlanRequest` |
| `BodyMetricTests/Services/WorkoutDayPlanServiceTests.swift` | Unit tests using MockNetworkClient |

---

## Modified Files

| File | What changes |
|------|-------------|
| `Services/WorkoutPlan/WorkoutPlanServiceProtocol.swift` | `saveDays` return type: `Void` → `[WorkoutPlanDayResponse]` |
| `Services/WorkoutPlan/WorkoutPlanService.swift` | Decode 201 body; return `[WorkoutPlanDayResponse]` |
| `Features/NewPlan/ViewModels/NewPlanViewModel.swift` | Add `workoutPlanIds`, `isDayConfigSaving`, `dayConfigSaveError`, `saveDayConfig(for:using:onSuccess:)` |
| `Features/NewPlan/Views/NewPlanWizardView.swift` | Add `dayConfigService` parameter; step 2 Continue → async `saveDayConfig` |
| `Features/Workout/Views/TodayView.swift` | Pass `WorkoutDayPlanService(networkClient: networkClient)` to wizard |

---

## WorkoutDayPlanService API

```swift
protocol WorkoutDayPlanServiceProtocol: AnyObject {
    func saveDayPlan(workoutPlanId: Int, request: WorkoutDayPlanRequest) async throws -> WorkoutDayPlanResponse
    func saveExerciseBlock(workoutDayPlanId: Int, request: ExerciseBlockPlanRequest) async throws
}
```

---

## NewPlanViewModel — saveDayConfig

```swift
func saveDayConfig(
    for day: DayOfWeek,
    dayIndex: Int,         // used to derive orderIndex
    using service: any WorkoutDayPlanServiceProtocol,
    onSuccess: @MainActor @Sendable () -> Void
) async {
    guard let plan = dayPlans[day],
          let planId = workoutPlanIds[day],
          !isDayConfigSaving else { return }
    isDayConfigSaving = true
    dayConfigSaveError = nil
    Logger.info("wizard_day_config_save_started day:\(day.shortLabel)")

    do {
        // 1. Save day plan
        let dayRequest = WorkoutDayPlanRequest(
            name: plan.sessionName,
            orderIndex: day.rawValue - 1,
            isActive: true
        )
        let dayResponse = try await service.saveDayPlan(workoutPlanId: planId, request: dayRequest)
        Logger.info("wizard_day_plan_saved workoutDayPlanId:\(dayResponse.workoutDayPlanId)")

        // 2. Save exercise blocks sequentially
        for block in plan.blocks {
            let blockRequest = ExerciseBlockPlanRequest(block: block)
            try await service.saveExerciseBlock(workoutDayPlanId: dayResponse.workoutDayPlanId, request: blockRequest)
        }
        Logger.info("wizard_exercise_blocks_saved count:\(plan.blocks.count)")

        onSuccess()
    } catch {
        Logger.error("wizard_day_config_save_failed", error: error)
        dayConfigSaveError = "Could not save your workout day. Please try again."
    }
    isDayConfigSaving = false
}
```

---

## NewPlanViewModel — updated saveDays (backward-compatible change)

```swift
// saveDays now stores planIds returned from step 1
func saveDays(
    using service: any WorkoutPlanServiceProtocol,
    onSuccess: @MainActor @Sendable () -> Void
) async {
    guard !isSaving else { return }
    isSaving = true
    saveErrorMessage = nil
    let requests = orderedSelectedDays.map(\.toRequest)
    do {
        let savedDays = try await service.saveDays(requests)  // NEW: now returns [WorkoutPlanDayResponse]
        // Store planId per DayOfWeek for use in step 2
        for response in savedDays {
            if let day = DayOfWeek(rawValue: response.plannedWeekNumber) {
                workoutPlanIds[day] = response.planId
            }
        }
        Logger.info("wizard_days_save_success dayCount:\(requests.count)")
        onSuccess()
    } catch {
        Logger.error("wizard_days_save_failed", error: error)
        saveErrorMessage = "Could not save your training days. Please try again."
    }
    isSaving = false
}
```

---

## NewPlanWizardView wiring (step 2)

```swift
struct NewPlanWizardView: View {
    let service: any WorkoutPlanServiceProtocol
    let dayConfigService: any WorkoutDayPlanServiceProtocol  // NEW
    ...
}

// In continueButton action for step 2:
if viewModel.currentStep >= 2 && viewModel.currentStep <= viewModel.totalSteps - 1 {
    if let day = viewModel.currentDayOfWeek {
        Task {
            await viewModel.saveDayConfig(
                for: day,
                using: dayConfigService,
                onSuccess: { viewModel.advance() }
            )
        }
    }
}
```

---

## TodayView — passing the new service

```swift
.fullScreenCover(isPresented: $showWizard) {
    NewPlanWizardView(
        service: WorkoutPlanService(networkClient: networkClient),
        dayConfigService: WorkoutDayPlanService(networkClient: networkClient)  // NEW
    )
}
```

---

## Interaction Trace Events

| Event | When |
|-------|------|
| `wizard_day_config_save_started` | `saveDayConfig` begins |
| `wizard_day_plan_saved` | Day plan POST 201 |
| `wizard_exercise_blocks_saved` | All block POSTs succeed |
| `wizard_day_config_save_failed` | Any POST fails |

---

## Testing Guide

### WorkoutDayPlanServiceTests

- `saveDayPlan` 201 → returns decoded `WorkoutDayPlanResponse` with correct `workoutDayPlanId`
- `saveDayPlan` 404 → throws server error
- `saveExerciseBlock` 201 → no throw
- `saveExerciseBlock` 500 → throws server error
- Verify request includes `Authorization: Bearer` header (handled by `NetworkClient`)
- Verify correct URL path construction with ids

### NewPlanViewModelTests (additions)

- `saveDayConfig` success → `onSuccess` called, `isDayConfigSaving == false`, `dayConfigSaveError == nil`
- `saveDayConfig` day plan failure → `dayConfigSaveError != nil`, `isDayConfigSaving == false`, advance NOT called
- `saveDayConfig` block failure (day saved, block fails) → error shown, advance NOT called
- `saveDays` success → `workoutPlanIds` populated from response
