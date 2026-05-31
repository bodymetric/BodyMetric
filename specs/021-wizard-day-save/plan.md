# Implementation Plan: Wizard Step 2 — Save Day Config on Continue

**Branch**: `021-wizard-day-save` | **Date**: 2026-05-31 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/021-wizard-day-save/spec.md`

## Summary

Spec 021 describes saving the full workout day configuration to the server when the user taps Continue on wizard step 2. **All 11 functional requirements are already implemented** across features 011, 013, and 020. This plan confirms that finding, maps each requirement to its existing code location, and proposes a verification task to ensure the end-to-end flow matches the spec exactly — including the per-set `targetSets` array introduced in feature 020.

## Technical Context

**Language/Version**: Swift 5.10
**Primary Dependencies**: URLSession via `NetworkClient` (existing); no new SPM packages
**Storage**: N/A — all data is sent to the server; no local persistence changes
**Testing**: XCTest (existing `NewPlanViewModelTests`, `WorkoutDayPlanServiceTests`)
**Target Platform**: iOS 17+
**Project Type**: Mobile app
**Performance Goals**: Save completes within 5 seconds (spec SC-001)
**Constraints**: No PII in logs; tokens never in logs (Constitution Principles III, VII); single in-flight request (FR-007)
**Scale/Scope**: 0 new files; existing code verified and documented

## Constitution Check

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ✅ | Pure Swift; no new dependencies |
| II. Comprehensive Testing | TDD; ≥ 90% coverage; tests before implementation | ✅ | `saveDayConfig` has 6+ unit tests; service tests verify payload |
| III. Error Logging | All errors logged; no PII | ✅ | `Logger.error("wizard_day_config_save_failed")` at catch site |
| IV. Interaction Tracing | All interactions traced; no PII | ✅ | `Logger.info("wizard_day_config_save_started")` + `wizard_day_plan_saved` |
| V. User-Friendly, Simple & Fast | Critical path minimal taps; <300 ms feedback | ✅ | `ProgressView` shown during save; error banner on failure |
| VI. Grayscale Visual Design | All UI grayscale | ✅ | No new UI elements added |
| VII. Token Security | Bearer token via Keychain; never in logs | ✅ | `NetworkClient` injects token; no token in log events |

## Project Structure

### Existing Implementation (no new files)

```text
Features/NewPlan/ViewModels/
└── NewPlanViewModel.swift          # saveDayConfig(for:using:onSuccess:) — lines 184–216
                                    # isDayConfigSaving, dayConfigSaveError state

Features/NewPlan/Views/
└── NewPlanWizardView.swift         # Continue button calls saveDayConfig — lines 197–206
                                    # stepDaySaving disables button — line 146

Features/NewPlan/Views/Components/
└── ConfigureDayStepView.swift      # Error banner displays dayConfigSaveError — lines 28–32

Services/WorkoutPlan/
├── WorkoutDayPlanService.swift     # POST /api/workout-plans/{id}/days
└── WorkoutDayPlanServiceProtocol.swift

Models/
└── WorkoutDayPlanModels.swift      # WorkoutDayPlanRequest, ExerciseBlockRequest, TargetSetRequest

BodyMetricTests/Features/
└── NewPlanViewModelTests.swift     # saveDayConfig tests — lines 496–543+

BodyMetricTests/Services/
└── WorkoutDayPlanServiceTests.swift  # Request payload + HTTP method tests
```

## Requirement Traceability

| FR | Requirement | Implemented In | Code Location |
|----|-------------|----------------|---------------|
| FR-001 | Save request sent on Continue tap | feature 011 | `NewPlanWizardView.swift:201–206` |
| FR-002 | Payload: name, orderIndex, isActive, exerciseBlocks | feature 013 | `NewPlanViewModel.swift:199–205` |
| FR-003 | Each block: exerciseId, orderIndex, restSeconds, isOptional, targetSets | feature 013 | `WorkoutDayPlanModels.swift:ExerciseBlockRequest.init` |
| FR-004 | Each set: orderIndex, targetReps, targetWeight | feature 020 | `WorkoutDayPlanModels.swift:ExerciseBlockRequest.init:28–33` |
| FR-005 | URL uses workoutPlanId from step 1 | feature 011 | `NewPlanViewModel.swift:191` + `WorkoutDayPlanService.swift:24` |
| FR-006 | Continue button disabled during save | feature 011 | `NewPlanWizardView.swift:146,170` |
| FR-007 | Single in-flight request guard | feature 011 | `NewPlanViewModel.swift:189` |
| FR-008 | Advance on success | feature 011 | `NewPlanViewModel.swift:210` (onSuccess callback) |
| FR-009 | Stay on step 2 + error message on failure | feature 011 | `NewPlanViewModel.swift:212–213` |
| FR-010 | Error cleared on next save attempt | feature 011 | `NewPlanViewModel.swift:194` |
| FR-011 | Bearer token in all requests | feature 010 | `NetworkClient.swift` — automatic injection |

## Complexity Tracking

No Constitution violations. No new complexity introduced.
