# Implementation Plan: Home Menu Dropdown

**Branch**: `006-home-menu-dropdown` | **Date**: 2026-04-25 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/006-home-menu-dropdown/spec.md`

## Summary

Add a top-right dropdown menu to the Today screen triggered by tapping the mascot chip. The menu contains seven navigation items (two active, five coming-soon) and navigates to a new multi-step New Plan wizard when "New Workout Plan" is tapped. The wizard lets users pick training days, configure exercise blocks per day, and save a local workout plan. Both surfaces use the existing GrayscalePalette/WorkoutPalette design system and follow the established SwiftUI patterns already present in the workout flow.

## Technical Context

**Language/Version**: Swift 5.10 / iOS 17+  
**Primary Dependencies**: SwiftUI (`@Observable`, `NavigationStack`, ZStack overlays), no new SPM packages required  
**Storage**: UserDefaults (via existing `ProfileStore` pattern) for saving the resulting `WorkoutPlan`; in-memory during wizard flow  
**Testing**: XCTest (unit) + XCUITest (UI journeys); Swift Testing acceptable alongside  
**Target Platform**: iOS 17+ iPhone (portrait-only)  
**Project Type**: Mobile app (feature module addition)  
**Performance Goals**: Menu open/close animation ≤ 300 ms (Constitution V); wizard step transitions ≤ 300 ms  
**Constraints**: All colors from `GrayscalePalette`; WorkoutPalette accent permitted within workout-flow screens (established project exception documented in `WorkoutPalette.swift`); no new SPM dependencies; ≥ 90% code coverage  
**Scale/Scope**: 2 new views + 1 modified view for the menu; ~10 new views/components for the wizard; ~18-exercise static catalog; 1 new ViewModel

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ✅ | No new SPM packages needed; all code is pure Swift/SwiftUI |
| II. Comprehensive Testing | TDD; ≥ 90% coverage; tests before implementation | ✅ | `NewPlanViewModel` unit tests + `HomeMenuView` unit tests required; UI test for P1 journey (open menu → tap New Workout Plan → wizard appears) |
| III. Error Logging | All errors logged with timestamp, severity, location, context; no PII | ✅ | No network calls in this feature; Logger.info traces for navigation events (menu opened, destination tapped) |
| IV. Interaction Tracing | All meaningful interactions traced; no PII in events | ✅ | Must trace: `menu_opened`, `menu_item_tapped` (destination: string), `menu_dismissed`, `wizard_day_toggled`, `wizard_step_advanced` (step: int), `wizard_finished`, `wizard_cancelled` |
| V. User-Friendly, Simple & Fast | Single primary action per screen; critical path minimal taps; <1 s launch; <300 ms feedback | ✅ | Menu open uses `.bmSpring` animation (≈350 ms — just over 300 ms threshold; use `.bmFade` for the overlay enter/exit to stay within 300 ms); wizard has one primary CTA per step |
| VI. Grayscale Visual Design | All UI colors must be grayscale; semantic meaning via shape/icon/text only | ✅ | `GrayscalePalette` for all structural colors; `WorkoutPalette.accentSoft/accentInk` permitted for the "New Workout Plan" icon cell and primary CTA fills — identical pattern to existing `TodayView`. Menu and wizard are part of the workout flow. `WorkoutPalette` must NOT be used outside these two screens. |
| VII. Token Security & Session Management | Bearer token in Authorization header; tokens in Keychain; delete on logout/expiry | ✅ | N/A — this feature introduces no authenticated network calls. The wizard saves locally only. |

## Project Structure

### Documentation (this feature)

```text
specs/006-home-menu-dropdown/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
└── tasks.md             ← Phase 2 output (created by /speckit.tasks — NOT here)
```

### Source Code

```text
Features/
├── Workout/
│   └── Views/
│       ├── TodayView.swift                   [MODIFY] add menuOpen state + Button on mascot chip + fullScreenCover
│       └── Components/
│           └── HomeMenuView.swift            [NEW] dropdown overlay panel + scrim
└── NewPlan/
    ├── Models/
    │   ├── NewPlanModels.swift               [NEW] WorkoutPlan, DayPlan, ExerciseBlock, Exercise catalog
    ├── ViewModels/
    │   └── NewPlanViewModel.swift            [NEW] @Observable wizard state machine
    └── Views/
        ├── NewPlanWizardView.swift           [NEW] root wizard container; step routing
        └── Components/
            ├── WizardStepRailView.swift      [NEW] step chip rail at wizard top
            ├── SelectDaysStepView.swift      [NEW] day-picker grid (step 1)
            ├── ConfigureDayStepView.swift    [NEW] session name + exercise blocks (steps 2…N)
            ├── ExerciseBlockRowView.swift    [NEW] single block row with steppers
            ├── ExercisePickerSheetView.swift [NEW] searchable exercise list (bottom sheet)
            ├── ReviewStepView.swift          [NEW] summary of all days (final step)
            └── PlanSavedView.swift           [NEW] success confirmation screen

BodyMetricTests/
└── Features/
    ├── HomeMenuViewModelTests.swift          [NEW] unit: menu open/close, item enabled/disabled
    └── NewPlanViewModelTests.swift           [NEW] unit: day toggle, block add/remove, step validation, finish
```

**Structure Decision**: iOS app with feature modules. New `Features/NewPlan/` mirrors the established `Features/Workout/` layout (Models / ViewModels / Views / Views/Components). The menu is a component of the `Workout` feature because it lives on `TodayView`.

## Complexity Tracking

> No Constitution violations requiring justification.
