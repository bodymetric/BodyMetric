# Research: Home Screen Workout Data — Corrected API Contract

**Date**: 2026-05-03

---

## 1. Field name fix: timeEstimateToFinishes → timeEstimateToFinish

**Decision**: Rename `WorkoutDayPlanSummary.timeEstimateToFinishes` to `timeEstimateToFinish`. Update all references in `TodayView.swift` and test fixtures.

**Rationale**: The actual API JSON key confirmed in the spec is `timeEstimateToFinish` (no trailing "s"). The 015 name was an assumption that was wrong.

---

## 2. New fields on WorkoutDayPlanSummary

**Decision**: Add `let id: Int` and `let dayOfWeek: String` to `WorkoutDayPlanSummary`.

- `id` is the server-assigned plan identifier (may be needed for future operations)
- `dayOfWeek` is a display label (e.g., "SUNDAY"); displayed on the workout card

---

## 3. TodayExercise gains orderIndex and sets

**Decision**: Add `let orderIndex: Int` and `let sets: [TodayExerciseSet]` to `TodayExercise`.

- Exercises are sorted by `orderIndex` before display
- `sets` contains one or more target set prescriptions

---

## 4. New TodayExerciseSet struct

**Decision**: `struct TodayExerciseSet: Decodable, Equatable { let orderIndex: Int; let targetReps: Int; let targetWeight: Double }`

Sets are sorted by `orderIndex` before display under each exercise.

---

## 5. 401 handling: already implemented

**Decision**: No new code needed. `NetworkClient.data(for:)` already handles 401 by calling `coordinator.refresh()` and retrying once. If the retry also returns 401, `coordinator` calls `forceLogout()` which redirects to login. The spec requirement US3 is fully satisfied by existing infrastructure.

---

## 6. Ordering implementation

**Decision**: Sort exercises by `TodayExercise.orderIndex` in `TodayViewModel.exercisesForToday` computed property (or in the View). Sort sets by `TodayExerciseSet.orderIndex` inline in the view when rendering.

Use `.sorted { $0.orderIndex < $1.orderIndex }` — simple, no extra dependencies.
