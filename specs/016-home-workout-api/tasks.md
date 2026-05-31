# Tasks: Home Screen Workout Data — Corrected API Contract

**Input**: Design documents from `/specs/016-home-workout-api/`  
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Scope**: 5 modified files, 0 new files. Corrects field names and adds missing fields from feature 015.

**Tests**: US3 (401 refresh) and US4 (error state) are already fully handled by existing `NetworkClient` and `TodayView` error card — no new code needed for those stories.

---

## Phase 1: Setup

No new directories or files required.

---

## Phase 2: Foundational — Model update (blocking all story phases)

**Purpose**: Update `HomeModels.swift` with corrected field names, new fields, and the new `TodayExerciseSet` struct. All downstream tasks depend on this compiling.

- [X] T001 Update `Models/HomeModels.swift`: (1) Add `let id: Int` and `let dayOfWeek: String` to `WorkoutDayPlanSummary`; (2) Rename `let timeEstimateToFinishes: Int` to `let timeEstimateToFinish: Int`; (3) Add `let orderIndex: Int` and `let sets: [TodayExerciseSet]` to `TodayExercise`; (4) Add new `struct TodayExerciseSet: Decodable, Equatable { let orderIndex: Int; let targetReps: Int; let targetWeight: Double }` after `TodayExercise`; (5) Add `Equatable` conformance to `TodayExerciseSet`; (6) Keep all other types unchanged

**Checkpoint**: Models compile. T002–T005 can now run in parallel.

---

## Phase 3: User Story 1 — User sees their current day's workout plan (Priority: P1) 🎯 MVP

**Goal**: Workout card shows `dayOfWeek` label and uses the correct `timeEstimateToFinish` field. Exercises list shows each exercise's target sets in `orderIndex` order.

**Independent Test**: Build succeeds; inject a mock `HomeScreenData` with two exercises (orderIndex 2 then 1) and one set each; verify exercises appear in ascending orderIndex order and sets are shown with reps and weight.

### Implementation for US1

- [X] T002 [P] [US1] Update `BodyMetricTests/Services/HomeServiceTests.swift`: (1) In `test_fetchHomeData_200_withPlan_returnsData` mock JSON, add `"id": 7`, `"dayOfWeek": "SUNDAY"`, rename `"timeEstimateToFinishes"` to `"timeEstimateToFinish"`, and add `"orderIndex": 1, "sets": [{"orderIndex": 1, "targetReps": 12, "targetWeight": 25.0}]` to the exercise entry; (2) Update assertion `result.currentWorkoutDayPlan?.timeEstimateToFinishes` → `result.currentWorkoutDayPlan?.timeEstimateToFinish`; (3) Add assertions: `XCTAssertEqual(result.currentWorkoutDayPlan?.id, 7)` and `XCTAssertEqual(result.currentWorkoutDayPlan?.dayOfWeek, "SUNDAY")`; (4) Add assertion `XCTAssertEqual(result.exercisesForToday?[0].sets[0].targetReps, 12)` and `XCTAssertEqual(result.exercisesForToday?[0].sets[0].targetWeight, 25.0)`; (5) In `test_fetchHomeData_200_noPlan_returnsNilPlan` and other mock JSON strings, add `"orderIndex": N, "sets": []` to any exercise entries; depends on T001

- [X] T003 [P] [US1] Update `Features/Workout/ViewModels/TodayViewModel.swift`: in `exercisesForToday` computed property, change `return d.exercisesForToday ?? []` to `return (d.exercisesForToday ?? []).sorted { $0.orderIndex < $1.orderIndex }` so exercises are returned in ascending `orderIndex` order; depends on T001

- [X] T004 [P] [US1] Update `Features/Workout/Views/TodayView.swift`: (1) In `populatedWorkoutCard(_:)`, add a day-of-week label directly below the plan name: `Text(plan.dayOfWeek.capitalized).font(.system(size: 13, design: .monospaced)).foregroundStyle(GrayscalePalette.background.opacity(0.65)).tracking(1.2)` with `.padding(.top, 2)`; (2) Fix the "est. min" `StatBadge` to use `plan.timeEstimateToFinish` instead of `plan.timeEstimateToFinishes`; (3) In `exercisesCard`, add target set details below each exercise name: `ForEach(ex.sets.sorted { $0.orderIndex < $1.orderIndex }, id: \.orderIndex) { set in Text("Set \(set.orderIndex): \(set.targetReps) reps × \(formattedWeight(set.targetWeight))kg").font(.system(size: 11, design: .monospaced)).foregroundStyle(GrayscalePalette.secondary) }`; depends on T001

- [X] T005 [P] [US1] Update `BodyMetricTests/Features/TodayViewModelTests.swift`: (1) In `makeHomeData(withPlan:exercises:)` helper, update `WorkoutDayPlanSummary` constructor to include `id: 1, dayOfWeek: "MONDAY"` and rename `timeEstimateToFinishes: 60` to `timeEstimateToFinish: 60`; (2) In `TodayExercise` construction, add `orderIndex: $0` and `sets: [TodayExerciseSet(orderIndex: 1, targetReps: 10, targetWeight: 20)]`; (3) Add test `test_exercisesForToday_sortedByOrderIndex` — create two exercises with orderIndex 2 and 1, call `loadHomeData`, assert `exercisesForToday[0].orderIndex == 1`; depends on T001

**Checkpoint**: All story phases complete. US2 (empty state), US3 (401), US4 (error) are already handled by existing code.

---

## Final Phase: Polish

- [X] T006 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED with no new errors

---

## Dependencies

```
T001 (HomeModels)
    ↓
T002 [P] + T003 [P] + T004 [P] + T005 [P]   (all parallel — different files)
    ↓
T006 (build)
```

---

## Notes

- T002, T003, T004, T005 can all run simultaneously after T001 compiles
- US3 (401 refresh+retry) and US4 (error+retry) need **zero new code** — already handled by `NetworkClient` and the existing error card in `TodayView`
- `timeEstimateToFinishes` → `timeEstimateToFinish` must be changed in both models and view references
- Set display uses `formattedWeight(_ w: Double)` helper already present in `TodayView`
- Commit convention: `✨ T001: correct HomeModels field names; add TodayExerciseSet`
