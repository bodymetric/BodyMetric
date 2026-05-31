# Research: Wizard Step 2 — Save Day Config on Continue

**Branch**: `021-wizard-day-save` | **Date**: 2026-05-31

## Finding: Feature Already Implemented

**Decision**: No new implementation required. All 11 functional requirements from spec 021 are satisfied by the existing codebase (features 011, 013, 020).

**Rationale**: The spec re-describes the existing behaviour. An audit of the live code against each requirement shows complete coverage.

**Alternatives considered**: Rewriting the save flow from scratch → rejected because the existing implementation is correct, tested, and production-ready.

---

## Audit: Requirement vs. Code

### FR-001 — Save on Continue tap

`NewPlanWizardView.swift` lines 197–206:
```swift
} else if let day = viewModel.currentDayOfWeek {
    if viewModel.isEditMode {
        viewModel.advance()
    } else {
        Task {
            await viewModel.saveDayConfig(for: day, using: dayConfigService) {
                viewModel.advance()
            }
        }
    }
}
```
In create mode (non-edit), Continue calls `saveDayConfig` before advancing. ✅

### FR-002 — Payload content (name, orderIndex, isActive, exerciseBlocks)

`NewPlanViewModel.swift` lines 199–205:
```swift
let request = WorkoutDayPlanRequest(
    name: plan.sessionName,
    orderIndex: day.orderIndex,
    isActive: true,
    exerciseBlocks: plan.blocks.enumerated().map { idx, block in
        ExerciseBlockRequest(block: block, orderIndex: idx + 1)
    }
)
```
All four fields present. ✅

### FR-003 — Each exercise block fields

`WorkoutDayPlanModels.swift — ExerciseBlockRequest.init(block:orderIndex:)`:
```swift
self.exerciseId  = Int(block.exerciseId) ?? 0
self.orderIndex  = orderIndex
self.restSeconds = block.restSeconds
self.isOptional  = false
self.targetSets  = block.sets.enumerated().map { ... }
```
All five fields present. ✅

### FR-004 — Each target set fields (per-set data, feature 020)

`WorkoutDayPlanModels.swift — ExerciseBlockRequest.init` lines 28–33:
```swift
self.targetSets = block.sets.enumerated().map { idx, set in
    TargetSetRequest(
        orderIndex: idx + 1,
        targetReps: set.targetReps,
        targetWeight: set.targetWeight
    )
}
```
Each set maps to `TargetSetRequest` with its position, rep count, and weight. ✅

### FR-005 — workoutPlanId from step 1

`NewPlanViewModel.swift:191`: `guard ... let planId = workoutPlanIds[day]`
`WorkoutDayPlanService.swift:24`: `URL(string: "\(Self.baseURL)/workout-plans/\(workoutPlanId)/days")`

`workoutPlanIds` is populated after step 1's `saveDays` response. ✅

### FR-006 + FR-007 — Button disabled; single request guard

`NewPlanWizardView.swift:146`: `let stepDaySaving = viewModel.isDayConfigSaving`
`NewPlanWizardView.swift:170`: `continueButton(enabled: canContinue && !stepDaySaving, isSaving: stepDaySaving)`
`NewPlanViewModel.swift:189`: `guard !isDayConfigSaving`

Button disabled for full duration; duplicate taps blocked. ✅

### FR-008 + FR-009 + FR-010 — Success/failure navigation and error handling

`NewPlanViewModel.swift:210–215`:
```swift
onSuccess()                             // FR-008: advance on success
} catch {
    dayConfigSaveError = "Could not save your workout day. Please try again."  // FR-009
}
isDayConfigSaving = false
```
And at line 194: `dayConfigSaveError = nil` (FR-010: cleared at start of each attempt). ✅

### FR-011 — Bearer token

`NetworkClient` injects `Authorization: Bearer <token>` on every request automatically (feature 010). ✅

---

## Test Coverage

`NewPlanViewModelTests.swift` — `saveDayConfig` tests:
- `test_saveDayConfig_success_callsOnSuccess` ✅
- `test_saveDayConfig_success_isDayConfigSavingFalseAfter` ✅
- `test_saveDayConfig_success_dayConfigSaveErrorNil` ✅
- `test_saveDayConfig_dayPlanFailure_onSuccessNotCalled` ✅
- `test_saveDayConfig_dayPlanFailure_dayConfigSaveErrorNotNil` ✅
- `test_saveDayConfig_dayPlanFailure_isDayConfigSavingFalse` ✅
- `test_saveDayConfig_success_requestContainsExerciseBlocks` ✅

`WorkoutDayPlanServiceTests.swift`:
- `test_saveDayPlan_requestBodyContainsExerciseBlocks` verifies `targetSets[0].targetReps == 12` ✅

---

## Edit Mode Note

In edit mode, Continue on step 2 calls `viewModel.advance()` directly without saving (line 199: `if viewModel.isEditMode { viewModel.advance() }`). This is intentional — edit mode uses `updatePlan` at the final step (feature 017). This scope is out of spec 021 and does not need to change.

---

## Conclusion

Spec 021 is fully satisfied by the existing codebase. The verification task is to run the build and confirm no regressions, then mark the spec complete.
