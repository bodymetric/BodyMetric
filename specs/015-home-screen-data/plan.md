# Implementation Plan: Home Screen Live Data

**Branch**: `015-home-screen-data` | **Date**: 2026-05-03 | **Spec**: [spec.md](spec.md)

## Summary

Replace the hardcoded mock data in `TodayView` with live data from `GET /api/home`. Introduce a `TodayViewModel` that owns the load state, a `HomeService` that fetches the endpoint, and update `TodayView` to render three states: skeleton (loading), populated workout card + optional exercises card (data present), empty workout card (no plan). Menu item states ("New Workout Plan" / "My Plans") become dynamic based on plan presence.

## Technical Context

**Language/Version**: Swift 5.10 / iOS 17+  
**Primary Dependencies**: SwiftUI (`@Observable`), URLSession via existing `NetworkClient`; no new SPM packages  
**Storage**: No local persistence; home data is fetched on every screen visit  
**Testing**: XCTest; new `HomeServiceTests` + `TodayViewModelTests`  
**Target Platform**: iOS 17+ iPhone  
**Project Type**: Mobile app — new service + ViewModel + significant TodayView refactor  
**Performance Goals**: Home data visible within 3 s (spec SC-001); skeleton shown within 300 ms of screen appearing (spec SC-004)  
**Constraints**: GrayscalePalette + WorkoutPalette; no new SPM deps; ≥ 90% coverage

## Constitution Check

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ✅ | Pure Swift; no new packages |
| II. Comprehensive Testing | TDD; ≥ 90% coverage | ✅ | HomeService tests + TodayViewModel tests |
| III. Error Logging | All errors logged; no PII in logs | ✅ | Logger.error at all catch sites |
| IV. Interaction Tracing | All interactions traced; no PII | ✅ | `home_data_load_started/success/failed` |
| V. User-Friendly, Simple & Fast | Skeleton ≤ 300 ms; data ≤ 3 s | ✅ | Skeleton shown immediately on .task trigger |
| VI. Grayscale Visual Design | All UI colors grayscale | ✅ | WorkoutPalette permitted for workout-flow CTA |
| VII. Token Security | Bearer token in header; Keychain storage | ✅ | NetworkClient handles token injection |

## Project Structure

### Source Code

```text
# New files
Models/HomeModels.swift                                    [NEW] HomeScreenData, WorkoutDayPlanSummary, TodayExercise
Services/Home/HomeServiceProtocol.swift                    [NEW] fetchHomeData() contract
Services/Home/HomeService.swift                            [NEW] GET /api/home
Features/Workout/ViewModels/TodayViewModel.swift           [NEW] @Observable load state machine

# Modified files
Features/Workout/Views/TodayView.swift                     [MODIFY] use TodayViewModel; skeleton/populated/empty states
Features/Workout/Views/Components/HomeMenuView.swift       [MODIFY] accept hasActivePlan param; dynamic item states
Features/Navigation/MainTabView.swift                      [MODIFY] inject HomeService + TodayViewModel to TodayView
App/BodyMetricApp.swift                                    [MODIFY] create HomeService

# New test files
BodyMetricTests/Services/HomeServiceTests.swift            [NEW] unit tests
BodyMetricTests/Features/TodayViewModelTests.swift         [NEW] unit tests
```

## Complexity Tracking

> No Constitution violations requiring justification.
