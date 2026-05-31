# Tasks: Home API — Replace targetSets with numberOfSets

**Input**: Design documents from `/specs/019-home-api-numberofsets/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Scope**: 3 modified files. No new files. No new directories. No new SPM packages.
**Tests**: Constitution Principle II requires ≥ 90% coverage. Tests are updated (not created from scratch) as part of each task.

---

## Phase 1: Setup

No new directories, packages, or project files required.

---

## Phase 2: Foundational — Delete TodayExerciseSet (blocking US1, US2, US3)

**Purpose**: Remove the dead `TodayExerciseSet` struct from `Models/HomeModels.swift`. This is the root blocking task — once the type is gone the compiler flags every remaining call site, making T002 and T003 self-documenting.

- [X] T001 Delete `TodayExerciseSet` struct from `Models/HomeModels.swift`: remove the entire `struct TodayExerciseSet: Decodable, Equatable { let orderIndex: Int; let targetReps: Int; let targetWeight: Double }` block; verify `TodayExercise` retains only `id: Int`, `name: String`, `orderIndex: Int`, `numberOfSets: Int`; verify `WorkoutDayPlanSummary` retains `numberSetsTotal: Int` (already present — confirm only)

**Checkpoint**: `TodayExerciseSet` no longer exists. Compiler will now report errors in TodayView.swift and TodayViewModelTests.swift — those are addressed in the next two tasks.

---

## Phase 3: User Story 1 — Home Screen Decodes numberOfSets Without targetSets (Priority: P1) 🎯 MVP

**Goal**: The home screen loads today's exercises, each displaying `numberOfSets` as a scalar integer. No `targetSets` array is decoded or referenced anywhere in the home pipeline. The compile errors introduced by T001 are resolved.

**Independent Test**: Run `HomeServiceTests` (already uses `numberOfSets`-compatible fixture). Confirm `test_fetchHomeData_success_decodesExercises` passes with `numberOfSets` on the decoded exercise. Confirm the app builds with zero `TodayExerciseSet` errors.

### Implementation for US1

- [X] T002 [US1] Update `Features/Workout/Views/TodayView.swift` preview stub: in `PreviewHomeServiceStub.fetchHomeData()`, replace both `TodayExercise(id: N, name: "...", orderIndex: N, sets: [TodayExerciseSet(orderIndex: 1, targetReps: ..., targetWeight: ...)])` calls with `TodayExercise(id: N, name: "...", orderIndex: N, numberOfSets: 3)` — 2 occurrences at lines ~448 and ~450; depends on T001

**Checkpoint**: US1 complete. App builds without errors related to `TodayExerciseSet`. `HomeServiceTests` pass. Home screen preview renders correctly.

---

## Phase 4: User Story 2 — All Data Consumers Updated (Priority: P2)

**Goal**: All remaining references to the old `sets: [TodayExerciseSet]` shape are eliminated from tests and fixtures. The full test suite passes.

**Independent Test**: Run `TodayViewModelTests`. All tests that previously constructed `TodayExercise` with `sets:` must now compile and pass using `numberOfSets:`.

### Implementation for US2

- [X] T003 [US2] Update `BodyMetricTests/Features/TodayViewModelTests.swift`: replace all 3 occurrences of `TodayExercise(id: N, name: "...", orderIndex: N, sets: [TodayExerciseSet(orderIndex: 1, targetReps: 10, targetWeight: 20)])` with `TodayExercise(id: N, name: "...", orderIndex: N, numberOfSets: 3)` — at lines ~96, ~98, ~116; depends on T001

**Checkpoint**: US1 + US2 complete. All `TodayExerciseSet` references are gone from the codebase. Full test suite passes.

---

## Phase 5: User Story 3 — Summary Totals Rendered from numberSetsTotal (Priority: P3)

**Goal**: Verify the workout card summary on the home screen displays `numberSetsTotal` correctly. This story requires no code changes — the `StatBadge(value: "\(plan.numberSetsTotal)", label: "sets")` binding in `TodayView.swift` was already implemented in feature 016. This phase is a validation checkpoint.

**Independent Test**: In `TodayViewModelTests`, confirm that when `WorkoutDayPlanSummary.numberSetsTotal` is set to 15, the loaded home state carries `numberSetsTotal == 15`. Visually verify the workout card shows "15 sets" in the preview.

### Implementation for US3

- [X] T004 [P] [US3] Verify `Features/Workout/Views/TodayView.swift`: confirm `StatBadge(value: "\(plan.numberSetsTotal)", label: "sets")` is present in the `populatedWorkoutCard` builder; confirm the updated preview stub from T002 passes `numberSetsTotal: 15` on `WorkoutDayPlanSummary`; no code changes needed if already correct — mark done after visual verification

**Checkpoint**: All 3 user stories complete. `numberOfSets` is the sole set-count representation in the home pipeline.

---

## Final Phase: Polish

- [X] T005 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED with zero errors mentioning `TodayExerciseSet` or `sets:`

---

## Dependencies

```
T001 (Delete TodayExerciseSet — foundational, blocks T002 + T003)
    ↓
T002 [US1] (Fix TodayView preview stubs — depends T001)
T003 [US2] (Fix TodayViewModelTests fixtures — depends T001, parallel with T002)
    ↓
T004 [US3] (Verify numberSetsTotal rendering — validation only, no code change)
    ↓
T005 (Build verification)
```

T002 and T003 are [P] relative to each other — different files, both unblock independently after T001.

---

## Notes

- `HomeServiceTests.swift` is already aligned with the new contract — no changes needed there.
- `WorkoutDayPlanModels.swift`, `WorkoutPlanModels.swift`, and their tests retain `targetSets` — those are for the plan-creation write path and are explicitly **out of scope**.
- T004 is a verification task, not an implementation task. If `StatBadge(value: "\(plan.numberSetsTotal)", label: "sets")` is present and the preview stub sets `numberSetsTotal: 15`, mark it done immediately.
- Constitution III: No new error sites introduced; existing HomeService logging is unchanged.
- Constitution VII: NetworkClient handles bearer token injection; no auth changes.
