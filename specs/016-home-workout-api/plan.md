# Implementation Plan: Home Screen Workout Data — Corrected API Contract

**Branch**: `016-home-workout-api` | **Date**: 2026-05-03 | **Spec**: [spec.md](spec.md)

## Summary

Corrects and extends the home screen data models introduced in feature 015. Changes:
1. `WorkoutDayPlanSummary`: add `id: Int`, add `dayOfWeek: String`, fix field name `timeEstimateToFinishes` → `timeEstimateToFinish`
2. `TodayExercise`: add `orderIndex: Int`, add `sets: [TodayExerciseSet]`
3. **New**: `TodayExerciseSet: Decodable, Equatable` with `orderIndex`, `targetReps`, `targetWeight`
4. **UI**: display `dayOfWeek` on workout card; sort exercises and sets by `orderIndex`; show target sets under each exercise

401 handling is already implemented by `NetworkClient` (token refresh + one retry); no new auth code is needed.

## Technical Context

**Language/Version**: Swift 5.10 / iOS 17+  
**Primary Dependencies**: Swift `Codable`; no new SPM packages  
**Storage**: No local persistence changes  
**Testing**: XCTest; update test fixtures in 2 test files  
**Target Platform**: iOS 17+ iPhone  
**Project Type**: Mobile app — model correction + UI update  
**Scope**: 4 modified files, 0 new files

## Delta from feature 015

| Component | Feature 015 | Feature 016 |
|-----------|-------------|-------------|
| `WorkoutDayPlanSummary.id` | missing | `let id: Int` |
| `WorkoutDayPlanSummary.dayOfWeek` | missing | `let dayOfWeek: String` |
| `WorkoutDayPlanSummary.timeEstimateToFinishes` | `let timeEstimateToFinishes: Int` | renamed to `let timeEstimateToFinish: Int` |
| `TodayExercise.orderIndex` | missing | `let orderIndex: Int` |
| `TodayExercise.sets` | missing | `let sets: [TodayExerciseSet]` |
| `TodayExerciseSet` | did not exist | new struct |
| Workout card UI | name/exercises/sets/duration | adds `dayOfWeek` label |
| Exercises card UI | exercise name only | name + target sets listed |
| Exercise ordering | undefined | sorted by `orderIndex` |
| Set ordering | n/a | sorted by `orderIndex` |

## Constitution Check

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ✅ | Pure Swift struct changes |
| II. Comprehensive Testing | TDD; ≥ 90% coverage | ✅ | Update test fixtures |
| III. Error Logging | All errors logged; no PII | ✅ | No change to logging |
| IV. Interaction Tracing | All interactions traced; no PII | ✅ | No new interactions |
| V. User-Friendly, Simple & Fast | Fast; <300 ms feedback | ✅ | No change to load timing |
| VI. Grayscale Visual Design | All UI colors grayscale | ✅ | GrayscalePalette throughout |
| VII. Token Security | Bearer token in header; Keychain | ✅ | NetworkClient already handles 401 |

## Project Structure (changed files only)

```text
Models/HomeModels.swift                            [MODIFY] correct fields; add id, dayOfWeek, orderIndex, sets, TodayExerciseSet
Features/Workout/Views/TodayView.swift             [MODIFY] display dayOfWeek; sort by orderIndex; show target sets per exercise

BodyMetricTests/Services/HomeServiceTests.swift    [MODIFY] update mock JSON + field assertions
BodyMetricTests/Features/TodayViewModelTests.swift [MODIFY] update WorkoutDayPlanSummary/TodayExercise constructors
```

## Complexity Tracking

> No Constitution violations requiring justification.
