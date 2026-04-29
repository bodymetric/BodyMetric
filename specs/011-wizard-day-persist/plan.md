# Implementation Plan: Workout Plan Wizard — Step 2 Day & Exercise Persistence

**Branch**: `011-wizard-day-persist` | **Date**: 2026-04-29 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/011-wizard-day-persist/spec.md`

**User clarification**: Persist each wizard step-2 day via `POST /api/workout-plans/{workoutPlanId}/days` (name, orderIndex, isActive: true), then persist each exercise block via `POST /api/workout-day-plans/{workoutDayPlanId}/exercise-blocks` using the ID returned by the day POST. Navigate forward only on full success.

## Summary

When the user taps Continue on step 2 of the wizard (Configure Day), the app:
1. POSTs the day plan (name + orderIndex + isActive) to `/api/workout-plans/{planId}/days`
2. Uses the returned `workoutDayPlanId` to POST each exercise block to `/api/workout-day-plans/{workoutDayPlanId}/exercise-blocks`
3. Advances the wizard only when all saves succeed; shows inline error and stays put on any failure.

This requires one backward-compatible change to existing feature 008 code: `WorkoutPlanService.saveDays` must decode the 201 response body to return `[WorkoutPlanDayResponse]` so that each day's `planId` is available for step 2.

## Technical Context

**Language/Version**: Swift 5.10 / iOS 17+  
**Primary Dependencies**: SwiftUI (`@Observable`), URLSession via existing `NetworkClient`; no new SPM packages  
**Storage**: No local persistence; all data saved to server  
**Testing**: XCTest (unit) + existing test helpers (`MockNetworkClient`)  
**Target Platform**: iOS 17+ iPhone  
**Project Type**: Mobile app — new service + ViewModel extension + View wiring  
**Performance Goals**: Day + blocks saved and wizard advances within 2 s under normal network  
**Constraints**: GrayscalePalette + WorkoutPalette (workout flow); ≥ 90% coverage; no new SPM deps  
**Scale/Scope**: 3 new files, 5 modified files, 2 new test files

## Constitution Check

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ✅ | Pure Swift; no new packages |
| II. Comprehensive Testing | TDD; ≥ 90% coverage; tests before implementation | ✅ | Service unit tests + ViewModel tests required before implementation |
| III. Error Logging | All errors logged; no PII in logs | ✅ | `Logger.error` at every catch site; no user data in messages |
| IV. Interaction Tracing | All interactions traced; no PII | ✅ | Trace events: `wizard_day_config_save_started`, `wizard_day_plan_saved`, `wizard_exercise_blocks_saved`, `wizard_day_config_save_failed` |
| V. User-Friendly, Simple & Fast | Single primary action; <300 ms feedback | ✅ | Continue button shows saving state; error shown in < 300 ms |
| VI. Grayscale Visual Design | All UI colors grayscale | ✅ | Error banner uses GrayscalePalette; WorkoutPalette permitted for CTA in workout flow |
| VII. Token Security | Bearer token in header; Keychain tokens; delete on logout | ✅ | NetworkClient handles token injection; no new auth code |

## Project Structure

### Documentation (this feature)

```text
specs/011-wizard-day-persist/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── contracts/           ← Phase 1 output
│   ├── post-workout-plan-day.md
│   └── post-exercise-block.md
└── tasks.md             ← Phase 2 output (created by /speckit.tasks)
```

### Source Code

```text
# New files
Services/WorkoutPlan/WorkoutDayPlanService.swift           [NEW] POST /days + POST /exercise-blocks
Services/WorkoutPlan/WorkoutDayPlanServiceProtocol.swift   [NEW] testable contract
Models/WorkoutDayPlanModels.swift                          [NEW] request/response DTOs

# Modified files (backward-compatible)
Services/WorkoutPlan/WorkoutPlanServiceProtocol.swift      [MODIFY] saveDays returns [WorkoutPlanDayResponse]
Services/WorkoutPlan/WorkoutPlanService.swift              [MODIFY] decode + return 201 response body
Features/NewPlan/ViewModels/NewPlanViewModel.swift         [MODIFY] add workoutPlanIds, saveDayConfig()
Features/NewPlan/Views/NewPlanWizardView.swift             [MODIFY] inject dayConfigService; wire step 2 Continue
Features/Workout/Views/TodayView.swift                     [MODIFY] pass WorkoutDayPlanService to wizard

# New test files
BodyMetricTests/Services/WorkoutDayPlanServiceTests.swift  [NEW] unit tests for both POST methods
BodyMetricTests/Features/NewPlanViewModelTests.swift       [MODIFY] add tests for saveDayConfig
```

**Structure Decision**: `WorkoutDayPlanService` lives alongside `WorkoutPlanService` in `Services/WorkoutPlan/`. DTOs live in `Models/`. Injection follows the established pattern: `TodayView` creates the concrete service and passes it to `NewPlanWizardView`.

## Complexity Tracking

> No Constitution violations requiring justification.
