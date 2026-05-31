# Implementation Plan: WorkoutPlanDayResponse Model Fix

**Branch**: `011-wizard-day-persist` | **Date**: 2026-04-30  
**User clarification**: The actual `GET /api/workout-plans` response uses `"id"` (not `"planId"`), uppercase `plannedDayOfWeek` values ("MONDAY"), `createdAt`, `days`, and `_links` fields. The existing struct was built from an earlier mock; it must now match the real API.

## Summary

`WorkoutPlanDayResponse` was modelled on an assumed schema that doesn't match the live API. The key difference is the primary key field: the server returns `"id"` but the struct declared `planId`. Every piece of code that reads `response.planId` and every test mock that produces `"planId"` in JSON must be updated. The `plannedWeekNumber` (Int) mapping that drives day pre-fill is unchanged.

## Changed fields

| Old field | New field | Notes |
|-----------|-----------|-------|
| `planId: Int` | `id: Int` | Direct JSON mapping; no CodingKeys needed |
| `plannedWeekNumber: Int` | unchanged | |
| `plannedDayOfWeek: String` | unchanged | Value now UPPERCASE ("MONDAY"), but field not used in logic |
| `executionCount: Int` | removed | Not in real response |
| `dayNames: [String]` | removed | Not in real response |
| `totalExercises: Int` | removed | Not in real response |
| `totalSets: Int` | removed | Not in real response |
| `estimatedDurationMinutes: Int` | removed | Not in real response |
| *(new)* `createdAt: String?` | added optional | Present in response; not used in logic |
| `var id: Int { planId }` | replaced by stored `id: Int` | Identifiable via stored property |

## Technical Context

**Language/Version**: Swift 5.10 / iOS 17+  
**Primary Dependencies**: Swift `Codable`; no new packages  
**Testing**: XCTest; update mocks and property references  
**Scope**: 4 modified files, 0 new files

## Constitution Check

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ✅ | Pure Swift struct change |
| II. Comprehensive Testing | TDD; ≥ 90% coverage; tests before implementation | ✅ | Tests updated to match new schema; existing decode tests verify the fix |
| III. Error Logging | All errors logged; no PII in logs | ✅ | No change to logging |
| IV. Interaction Tracing | All interactions traced; no PII | ✅ | No change to traces |
| V. User-Friendly, Simple & Fast | Token refresh transparent; <300 ms feedback | ✅ | No UI changes |
| VI. Grayscale Visual Design | All UI colors grayscale | ✅ | No UI changes |
| VII. Token Security | Bearer token in header; Keychain storage | ✅ | No change to auth layer |

## Project Structure (changed files only)

```text
Models/WorkoutPlanModels.swift                            [MODIFY] rewrite WorkoutPlanDayResponse
Features/NewPlan/ViewModels/NewPlanViewModel.swift        [MODIFY] response.planId → response.id (1 line)
BodyMetricTests/Services/WorkoutPlanServiceTests.swift    [MODIFY] mock JSON + assertion references
BodyMetricTests/Features/NewPlanViewModelTests.swift      [MODIFY] constructor calls (many lines)
```

## Complexity Tracking

> No Constitution violations requiring justification.
