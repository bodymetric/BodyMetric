# Implementation Plan: Home API — Replace targetSets with numberOfSets

**Branch**: `019-home-api-numberofsets` | **Date**: 2026-05-24 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/019-home-api-numberofsets/spec.md`

## Summary

Remove the `TodayExerciseSet` type and any remaining `sets: [TodayExerciseSet]` references from the home screen data pipeline. The `TodayExercise` model already carries `numberOfSets: Int`; `WorkoutDayPlanSummary` already carries `numberSetsTotal: Int`. This feature completes the cleanup: deletes the dead struct, updates preview stubs and test fixtures that still reference the old shape, and ensures the UI renders set count from the scalar field. Scope is strictly the home screen read path — plan-creation write path (`ExerciseBlockRequest`, `TargetSetRequest`) is unaffected.

## Technical Context

**Language/Version**: Swift 5.10  
**Primary Dependencies**: SwiftUI (`@Observable`), URLSession via `NetworkClient` (existing)  
**Storage**: N/A — home data is server-fetched on every visit; no local persistence change  
**Testing**: XCTest with `@MainActor`  
**Target Platform**: iOS 17+  
**Project Type**: iOS mobile app  
**Performance Goals**: Home screen load under 2 seconds (existing NetworkClient SLA)  
**Constraints**: Zero new warnings or errors after cleanup; no new SPM packages  
**Scale/Scope**: 3 modified files + 1 deleted type; no new files required

## Constitution Check

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ✅ | Pure Swift cleanup; no new packages |
| II. Comprehensive Testing | TDD; ≥ 90% coverage; tests before implementation | ✅ | Tests updated as part of each task; no coverage drop expected |
| III. Error Logging | All errors logged with timestamp, severity, location, context; no PII | ✅ | No new error sites; existing HomeService logging unchanged |
| IV. Interaction Tracing | All meaningful interactions traced; no PII in events | ✅ | No new user interactions introduced |
| V. User-Friendly, Simple & Fast | Single primary action per screen; <300 ms feedback | ✅ | UI rendering unchanged — only data source simplified |
| VI. Grayscale Visual Design | All UI colors must be grayscale | ✅ | No new color values; existing palette unchanged |
| VII. Token Security & Session Management | Tokens in Keychain only; never in logs | ✅ | NetworkClient handles bearer token injection; no changes to auth layer |

## Project Structure

### Documentation (this feature)

```text
specs/019-home-api-numberofsets/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── contracts/           ← Phase 1 output
└── tasks.md             ← Phase 2 output (/speckit-tasks command)
```

### Source Code (modified files only)

```text
Models/
└── HomeModels.swift                       # delete TodayExerciseSet struct

Features/Workout/Views/
└── TodayView.swift                        # update preview stubs: sets: → numberOfSets:

BodyMetricTests/Features/
└── TodayViewModelTests.swift              # update exercise fixtures: sets: → numberOfSets:

BodyMetricTests/Services/
└── HomeServiceTests.swift                 # verify/update home fixture (already aligned)
```

**Structure Decision**: iOS mobile app (Option 3 in template). Feature is a cleanup pass across model, view, and test layers. No new directories or files needed.

## Complexity Tracking

No Constitution violations. No complexity justification required.
