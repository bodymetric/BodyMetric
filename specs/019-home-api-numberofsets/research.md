# Research: Home API — Replace targetSets with numberOfSets

**Branch**: `019-home-api-numberofsets` | **Date**: 2026-05-24

## Current State Audit

Before writing the implementation plan, the codebase was audited to determine what remains to be changed.

### HomeModels.swift — Partial: model shape is correct, dead type remains

**Decision**: `TodayExercise` already has `numberOfSets: Int` and `WorkoutDayPlanSummary` already has `numberSetsTotal: Int`. However, `TodayExerciseSet` struct still exists in the file and must be deleted.

**Rationale**: Feature 016 introduced the home screen and partially implemented the contract. The scalar fields were added but the old `TodayExerciseSet` type was never removed.

**Alternatives considered**: Keeping `TodayExerciseSet` for future use — rejected because nothing consumes it in production code; it only appears in test fixtures and preview stubs.

### TodayView.swift — Broken: preview stubs use old `sets:` parameter

**Decision**: The `PreviewHomeServiceStub` in `TodayView.swift` constructs `TodayExercise` with `sets: [TodayExerciseSet(...)]`. Since `TodayExercise` does not have a `sets` property, these calls cause a compile error. They must be updated to use `numberOfSets: Int`.

**Rationale**: Preview stubs lagged behind the model update. This is the primary compile error blocking the feature.

**Alternatives considered**: Re-adding `sets` to `TodayExercise` — rejected; the contract is clear: only `numberOfSets` is needed for home screen display.

### TodayViewModelTests.swift — Broken: test fixtures use old `sets:` parameter

**Decision**: Test fixtures construct `TodayExercise` with `sets: [TodayExerciseSet(...)]`. Same fix as TodayView.swift — replace with `numberOfSets: N`.

**Rationale**: Tests were written before the model was finalized. Updating them completes the contract migration and restores CI.

### HomeServiceTests.swift — Already correct

**Decision**: `HomeServiceTests.swift` already uses `numberSetsTotal` in its fixture JSON and assertions. No changes needed.

**Rationale**: This test file was written after `HomeModels.swift` was partially updated.

### Out-of-scope findings

The following `targetSets` references exist in the codebase but are **not** part of this feature (they belong to the plan-creation write path, not the home screen read path):

- `Models/WorkoutDayPlanModels.swift` — `ExerciseBlockRequest.targetSets` (POST request body for saving days)
- `Models/WorkoutPlanModels.swift` — `CurrentExerciseBlock.targetSets` (GET current plan response)
- `BodyMetricTests/Services/WorkoutDayPlanServiceTests.swift` — verifies POST body shape
- `BodyMetricTests/Services/WorkoutPlanServiceTests.swift` — verifies current plan decode
- `BodyMetricTests/Features/NewPlanViewModelTests.swift` — verifies wizard save logic

These are untouched by this feature.

## Implementation Strategy

**No new files.** 3 file modifications: `HomeModels.swift` (delete struct), `TodayView.swift` (update preview), `TodayViewModelTests.swift` (update fixtures). `HomeServiceTests.swift` is confirmed correct and needs no changes.

**Order**: Delete `TodayExerciseSet` first (T001) so the compiler flags every remaining reference, then fix each call site (T002, T003) before verifying build (T004).
