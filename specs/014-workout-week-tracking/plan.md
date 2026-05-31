# Implementation Plan: Automated Training Week Tracking

**Branch**: `014-workout-week-tracking` | **Date**: 2026-05-02 | **Spec**: [spec.md](spec.md)

## Summary

This feature is **primarily server-side**. The mobile app's role is to adapt its request and response models:

1. **Stop sending** `plannedWeekNumber` in the step-1 POST payload (`WorkoutPlanDayRequest`)
2. **Stop expecting** `plannedWeekNumber` in plan responses (`WorkoutPlanDayResponse`) — it's already not used in logic since feature 008
3. **Start consuming** `actualWeekNumber` from plan responses (display to user — future)
4. **Update all test fixtures** that construct these models

The week progression, cycle completion detection, and `actualWeekNumber` increment logic all live on the server. The app only reads the server-provided `actualWeekNumber`.

## Technical Context

**Language/Version**: Swift 5.10 / iOS 17+  
**Primary Dependencies**: Swift `Codable`; no new SPM packages  
**Storage**: No local persistence changes  
**Testing**: XCTest; update test fixtures in 2 test files  
**Target Platform**: iOS 17+ iPhone  
**Project Type**: Mobile app — model cleanup + test fixture updates  
**Scope**: 3 production files, 2 test files

## Key changes

| File | Change |
|------|--------|
| `Models/WorkoutPlanModels.swift` | Remove `plannedWeekNumber: Int` from `WorkoutPlanDayResponse`; remove `plannedWeekNumber: String` from `WorkoutPlanDayRequest`; add `actualWeekNumber: Int?` to `WorkoutPlanDayResponse` |
| `Features/NewPlan/Models/NewPlanModels.swift` | Remove `plannedWeekNumber: String(rawValue)` from `DayOfWeek.toRequest`; update `WorkoutPlanDayRequest` init |
| `BodyMetricTests/Services/WorkoutPlanServiceTests.swift` | Update mock JSON + request constructors + assertions |
| `BodyMetricTests/Features/NewPlanViewModelTests.swift` | Update `WorkoutPlanDayResponse` constructors |

## Constitution Check

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ✅ | Pure Swift struct changes |
| II. Comprehensive Testing | TDD; ≥ 90% coverage | ✅ | Update existing tests; no new untested code |
| III. Error Logging | All errors logged; no PII in logs | ✅ | No change to logging |
| IV. Interaction Tracing | All interactions traced; no PII | ✅ | No new interactions |
| V. User-Friendly, Simple & Fast | Token refresh transparent; <300 ms feedback | ✅ | No UI changes in this slice |
| VI. Grayscale Visual Design | All UI colors grayscale | ✅ | No UI changes |
| VII. Token Security | Bearer token in header; Keychain storage | ✅ | No change to auth layer |

## Project Structure (changed files only)

```text
Models/WorkoutPlanModels.swift                            [MODIFY] remove plannedWeekNumber; add actualWeekNumber?
Features/NewPlan/Models/NewPlanModels.swift               [MODIFY] remove plannedWeekNumber from DayOfWeek.toRequest

BodyMetricTests/Services/WorkoutPlanServiceTests.swift    [MODIFY] update mock JSON + constructors
BodyMetricTests/Features/NewPlanViewModelTests.swift      [MODIFY] update WorkoutPlanDayResponse constructors
```

## Complexity Tracking

> No Constitution violations requiring justification.
