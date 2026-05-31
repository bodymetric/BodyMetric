# Implementation Plan: Wizard Step 2 — Persist Day Plan with Exercise Blocks

**Branch**: `013-wizard-day-blocks-persist` | **Date**: 2026-05-02 | **Spec**: [spec.md](spec.md)

## Summary

Replace the two-step save (feature 011: separate POSTs for day plan + exercise blocks) with a **single unified POST** per day. The request body now embeds exercise blocks — each with an order index, rest time, optional flag, and an array of target sets — directly inside the day plan payload. Accept 200 or 201 as success. Navigation through days is unchanged (existing `advance()` logic).

## Technical Context

**Language/Version**: Swift 5.10 / iOS 17+  
**Primary Dependencies**: SwiftUI (`@Observable`), URLSession via existing `NetworkClient`; no new SPM packages  
**Storage**: No local persistence; all data saved to server  
**Testing**: XCTest; update `WorkoutDayPlanServiceTests` + ViewModel tests  
**Target Platform**: iOS 17+ iPhone  
**Project Type**: Mobile app — request model redesign + service update + ViewModel simplification  
**Performance Goals**: Single POST replaces 1 + N POSTs → faster save; < 5 s under normal network  
**Constraints**: GrayscalePalette + WorkoutPalette; no new SPM deps; ≥ 90% coverage

## Delta from feature 011

| Component | Feature 011 | Feature 013 |
|-----------|-------------|-------------|
| `WorkoutDayPlanRequest` | `{ name, orderIndex, isActive }` | `{ name, orderIndex, isActive, exerciseBlocks: [...] }` |
| `ExerciseBlockPlanRequest` | Separate struct for `/exercise-blocks` POST | Renamed to `ExerciseBlockRequest`, now nested inside day request |
| `TargetSetRequest` | Did not exist | New: `{ orderIndex, targetReps, targetWeight }` |
| `WorkoutDayPlanService.saveDayPlan` | Accepts 201 only | Accepts 200 or 201 |
| `WorkoutDayPlanService.saveExerciseBlock` | Separate method | Removed |
| `WorkoutDayPlanServiceProtocol` | `saveDayPlan` + `saveExerciseBlock` | `saveDayPlan` only |
| `NewPlanViewModel.saveDayConfig` | 2-step (day then blocks) | 1-step (day + blocks in body) |

## isOptional and multiple target sets

- `ExerciseBlock` has no `isOptional` field → default to `false` in request builder (FR-009 assumption).
- `ExerciseBlock` has one set of targets (`targetReps`, `targetWeight`) → wrap as a single-element `targetSets` array with `orderIndex: 1`. This satisfies the API contract while keeping the UI simple; multi-set support is future scope.

## Constitution Check

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ✅ | Pure Swift; no new packages |
| II. Comprehensive Testing | TDD; ≥ 90% coverage | ✅ | Update service + ViewModel tests |
| III. Error Logging | All errors logged; no PII in logs | ✅ | Logger.error at all catch sites |
| IV. Interaction Tracing | All interactions traced; no PII | ✅ | `wizard_day_config_save_started/saved/failed` |
| V. User-Friendly, Simple & Fast | Single primary action; < 300 ms feedback | ✅ | Button disabled during save; single POST is faster |
| VI. Grayscale Visual Design | All UI colors grayscale | ✅ | No UI changes |
| VII. Token Security | Bearer token in header; Keychain storage | ✅ | NetworkClient handles token injection |

## Project Structure (changed files only)

```text
Models/WorkoutDayPlanModels.swift                      [MODIFY] new nested request types + accept 200/201
Services/WorkoutPlan/WorkoutDayPlanServiceProtocol.swift [MODIFY] remove saveExerciseBlock; update saveDayPlan signature
Services/WorkoutPlan/WorkoutDayPlanService.swift         [MODIFY] remove saveExerciseBlock; accept 200 or 201
Features/NewPlan/ViewModels/NewPlanViewModel.swift       [MODIFY] simplify saveDayConfig to single POST

BodyMetricTests/Services/WorkoutDayPlanServiceTests.swift [MODIFY] update tests for unified request
BodyMetricTests/Features/NewPlanViewModelTests.swift      [MODIFY] update saveDayConfig tests
```

## Complexity Tracking

> No Constitution violations requiring justification.
