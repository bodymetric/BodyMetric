# Implementation Plan: Wizard Step 2 — Live Exercise Catalog

**Branch**: `012-wizard-exercise-catalog` | **Date**: 2026-05-01 | **Spec**: [spec.md](spec.md)

**User clarification**: Load `GET /api/exercises` once on step-2 open; share result across all exercise pickers. Response: `[{ group, exercises: [{ id: Int, name: String }] }]`. Replace the static 18-exercise catalog with live API data.

## Summary

Step 2 of the New Plan wizard currently uses a hardcoded 18-exercise catalog with string IDs (e.g., `"bench"`). This feature replaces it with real exercises from `GET /api/exercises` (integer IDs, pre-grouped by muscle). The catalog loads once when step 2 first appears; all pickers on that screen share the same loaded data. A new `ExerciseService` fetches the catalog; `NewPlanViewModel` owns the cached result and load state.

## Technical Context

**Language/Version**: Swift 5.10 / iOS 17+  
**Primary Dependencies**: SwiftUI (`@Observable`), URLSession via existing `NetworkClient`; no new SPM packages  
**Storage**: No persistence; catalog is in-memory for the wizard session  
**Testing**: XCTest; new `ExerciseServiceTests` + ViewModel test additions  
**Target Platform**: iOS 17+ iPhone  
**Project Type**: Mobile app — new service + ViewModel extension + view updates  
**Performance Goals**: Catalog available within 2 s (spec SC-001); zero duplicate requests (spec SC-002)  
**Constraints**: GrayscalePalette + WorkoutPalette; no new SPM deps; ≥ 90% coverage

## Key changes vs. existing code

| Component | Before | After |
|-----------|--------|-------|
| `Exercise.id` | `String` ("bench") | No longer used for picker — replaced by `ApiExercise.id: Int` |
| `ExerciseBlock.exerciseId` | `String` ("bench") | `String` storing Int as string ("26") — minimal disruption |
| `ExerciseBlockPlanRequest.exerciseId` | `String` | `Int` (parsed from exerciseId string) |
| `ExercisePickerSheetView` | Uses `Exercise.catalog` static | Accepts `[ExerciseCatalogGroup]` parameter |
| `ExerciseBlockRowView` | Looks up name from `Exercise.catalog` | Accepts `exerciseName: String?` from parent |

## Constitution Check

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ✅ | Pure Swift; no new packages |
| II. Comprehensive Testing | TDD; ≥ 90% coverage | ✅ | ExerciseServiceTests + ViewModel catalog tests |
| III. Error Logging | All errors logged; no PII | ✅ | Logger.error at all catch sites |
| IV. Interaction Tracing | All interactions traced; no PII | ✅ | exercise_catalog_load_started/success/failed |
| V. User-Friendly, Simple & Fast | Loading indicator ≤ 300 ms | ✅ | Skeleton shown while loading |
| VI. Grayscale Visual Design | All UI colors grayscale | ✅ | GrayscalePalette + WorkoutPalette for selected cell |
| VII. Token Security | Bearer token in header; Keychain storage | ✅ | NetworkClient handles token injection automatically |

## Project Structure

### Source Code

```text
# New files
Models/ExerciseCatalogModels.swift                              [NEW] ApiExercise, ExerciseCatalogGroup DTOs
Services/Exercise/ExerciseServiceProtocol.swift                 [NEW] fetchExerciseCatalog() contract
Services/Exercise/ExerciseService.swift                         [NEW] GET /api/exercises
BodyMetricTests/Services/ExerciseServiceTests.swift             [NEW] unit tests

# Modified files
Features/NewPlan/ViewModels/NewPlanViewModel.swift              [MODIFY] add exerciseGroups, catalog load state/method
Features/NewPlan/Views/Components/ExercisePickerSheetView.swift [MODIFY] accept catalog param, remove static usage
Features/NewPlan/Views/Components/ExerciseBlockRowView.swift    [MODIFY] accept exerciseName: String? param
Features/NewPlan/Views/Components/ConfigureDayStepView.swift    [MODIFY] trigger load, pass catalog to picker
Features/NewPlan/Views/NewPlanWizardView.swift                  [MODIFY] add exerciseService parameter
Features/Workout/Views/TodayView.swift                          [MODIFY] pass ExerciseService to wizard
Models/WorkoutDayPlanModels.swift                               [MODIFY] ExerciseBlockPlanRequest.exerciseId: String→Int
```

## Complexity Tracking

> No Constitution violations requiring justification.
