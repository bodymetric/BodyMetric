# Implementation Plan: New Plan Wizard — Day Selection Screen

**Branch**: `008-wizard-day-selection` | **Date**: 2026-04-26 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/008-wizard-day-selection/spec.md`

**User clarification**: The POST `/api/workout-plans` is a server-side replace-all (upsert). The app simply POSTs the complete array of selected days. No client-side delete is needed.

## Summary

Add API integration to the first step of the New Plan wizard (day selection). On screen open, fetch the user's existing workout-plan days and pre-check the matching weekday checkboxes. When the user taps Continue with ≥1 day selected, POST the full array of selected days; navigate to step 2 on 201, show an inline error banner on any other response. The `NetworkClient` (already exists) handles bearer token injection and 401 retry transparently.

## Technical Context

**Language/Version**: Swift 5.10 / iOS 17+  
**Primary Dependencies**: SwiftUI (`@Observable`), URLSession (via existing `NetworkClient`); no new SPM packages  
**Storage**: No local persistence for this feature (day selections live on the server); existing `WorkoutPlanStore` (UserDefaults) is unaffected  
**Testing**: XCTest (unit) + XCUITest (UI); ≥ 90% coverage  
**Target Platform**: iOS 17+ iPhone (portrait-only)  
**Project Type**: Mobile app feature — new service layer + ViewModel mutation  
**Performance Goals**: GET response pre-fills UI within 2 s (spec SC-002); loading indicator ≤ 300 ms feedback (Principle V)  
**Constraints**: All colors GrayscalePalette / WorkoutPalette; no new SPM dependencies; bearer token injected by existing `NetworkClient`; ≥ 90% coverage  
**Scale/Scope**: 1 new service (2 methods: fetch + save), 1 ViewModel mutation, 2 view modifications (loading + error states)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ✅ | Pure Swift; no new SPM packages |
| II. Comprehensive Testing | TDD; ≥ 90% coverage; tests before implementation | ✅ | Service protocol mock + ViewModel unit tests required; UI test for P1 journey |
| III. Error Logging | All errors logged with timestamp, severity, location, context; no PII | ✅ | Logger.error at every network catch site; no tokens or user data logged |
| IV. Interaction Tracing | All meaningful interactions traced; no PII in events | ✅ | Must trace: `wizard_days_load_started`, `wizard_days_load_success`, `wizard_days_load_empty`, `wizard_days_load_failed`, `wizard_days_save_started`, `wizard_days_save_success`, `wizard_days_save_failed` |
| V. User-Friendly, Simple & Fast | Single primary action per screen; critical path minimal taps; <1 s launch; <300 ms feedback | ✅ | Loading indicator shown immediately on-appear; Continue is the single primary action; error banner is subordinate |
| VI. Grayscale Visual Design | All UI colors must be grayscale; semantic meaning via shape/icon/text only | ✅ | Loading spinner + error banner use GrayscalePalette; WorkoutPalette permitted for day chip and Continue CTA (workout-flow screen) |
| VII. Token Security & Session Management | Bearer token in Authorization header; tokens in Keychain; delete on logout/expiry | ✅ | `NetworkClient.data(for:)` already injects `Authorization: Bearer <token>`; no new token handling code needed |

## Project Structure

### Documentation (this feature)

```text
specs/008-wizard-day-selection/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── contracts/           ← Phase 1 output
│   ├── get-workout-plans.md
│   └── post-workout-plans.md
└── tasks.md             ← Phase 2 output (created by /speckit.tasks)
```

### Source Code

```text
Services/
└── WorkoutPlan/
    ├── WorkoutPlanService.swift           [NEW] GET + POST /api/workout-plans
    ├── WorkoutPlanServiceProtocol.swift   [NEW] testable contract
    └── WorkoutPlanError.swift             [NEW] domain error enum

Features/NewPlan/
├── ViewModels/
│   └── NewPlanViewModel.swift            [MODIFY] add loadDays() + saveDays() async methods; load/save state
└── Views/
    └── Components/
        └── SelectDaysStepView.swift      [MODIFY] add loading skeleton + inline error banner

BodyMetricTests/
└── Services/
    └── WorkoutPlanServiceTests.swift     [NEW] unit tests for service; mock NetworkClient
BodyMetricTests/
└── Features/
    └── NewPlanViewModelTests.swift       [MODIFY] add tests for loadDays/saveDays, loading/error states
```

**Structure Decision**: New `WorkoutPlanService` lives in `Services/WorkoutPlan/` following the existing `Services/Profile/UserProfileService.swift` pattern. ViewModel changes are in-place modifications. No new feature module needed.

## Complexity Tracking

> No Constitution violations requiring justification.
