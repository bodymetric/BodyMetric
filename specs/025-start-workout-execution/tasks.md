# Tasks: Start Workout Execution

**Input**: Design documents from `/specs/025-start-workout-execution/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ quickstart.md ✅

**Scope**: 7 source files modified, 2 test files updated. No new files.

---

## Phase 1: Setup

No new directories, packages, or project files required.

---

## Phase 2: Foundational — Replace API DTOs and Domain Models

These tasks must complete first because every other file depends on the new types.

- [X] T001 In `Models/WorkoutExecutionModels.swift`: replace `StartSessionResponse`, `SessionExercise`, `SessionSet` with `StartWorkoutResponse`, `ExerciseBlockPlan`, `TargetSet` matching the new API response (see plan.md Implementation Notes). Keep `StartSessionRequest` unchanged. Make `StartWorkoutResponse` conform to `Decodable, Hashable`. Update `toWorkoutSession()` to map `workExecutionId → WorkoutSession.id`, `workoutPlanName → name`, `exerciseBlockPlans` sorted by `orderIndex → exercises`, `exerciseName → WorkoutExercise.name`, `targetSets` sorted by `orderIndex → sets`, `targetWeight → WorkoutSet.targetWeight`. Update `ReadyToLiftViewModel.sessionResponse` type from `StartSessionResponse?` to `StartWorkoutResponse?`.

- [X] T002 In `Features/Workout/Models/WorkoutModels.swift`: (a) change `WorkoutSession.id` from `String` to `Int`; (b) update `WorkoutExercise`: change `id` from `String` to `Int`, add `exerciseBlockPlanId: Int`, remove `muscle: String` and `pr: PRRecord?`; (c) update `WorkoutSet`: remove `prevWeight: Double` and `prevReps: Int`, add `targetWeight: Double`; (d) update `SetProgress`: remove `prevWeight: Double` and `prevReps: Int`, add `targetWeight: Double`; (e) update `ExerciseProgress.id` from `String` to `Int`; (f) update `mockToday` static to compile with the new fields (use placeholder `exerciseBlockPlanId: 0`, `targetWeight` values, remove `muscle`/`pr` references).

---

## Phase 3: User Story 1 — Begin Session Starts the Workout (Priority: P1) 🎯

**Goal**: After "Begin Session" succeeds, navigate to `ActiveSessionView` displaying `workoutPlanName`, `totalNumberOfSets`, exercise blocks ordered by `orderIndex`, and target sets with `targetReps`/`targetWeight`. `workExecutionId` is retained in `ActiveSessionViewModel`.

**Independent Test**: Provide a mock `StartWorkoutResponse`; confirm `ActiveSessionView` renders with correct exercise names, set counts, and `workExecutionId` stored in the view model.

- [X] T003 [US1] In `Features/Workout/ViewModels/ActiveSessionViewModel.swift`: add `let workExecutionId: Int` property; update `init` to `init(workExecutionId: Int, workout: WorkoutSession, mood: String)`; update `SetProgress` initialisation inside `init` to use `targetWeight: s.targetWeight` instead of the removed `prevWeight`/`prevReps` fields; update `ExerciseProgress(id:)` to pass `Int` id.

- [X] T004 [US1] In `Features/Workout/Views/CheckInView.swift`: (a) change `.navigationDestination(for: StartSessionResponse.self)` to `.navigationDestination(for: StartWorkoutResponse.self)`; (b) update the view model construction to `ActiveSessionViewModel(workExecutionId: response.workExecutionId, workout: response.toWorkoutSession(), mood: mood?.rawValue.uppercased() ?? "")`; (c) no other changes needed — `viewModel.sessionResponse` type change cascades from T001.

- [X] T005 [US1] In `Features/Workout/Views/Components/ExerciseCard.swift`: (a) remove `· \(exercise.muscle)` from the subtitle `Text` (line ~43); (b) remove the entire PR badge `if let pr = exercise.pr` block (lines ~50–59); (c) rename the "PREVIOUS" column header to "TARGET" in the expanded set rows (line ~82); (d) update `SetRowView` body: replace `Text("\(formattedWeight(set.prevWeight))kg × \(set.prevReps)")` with `Text("\(formattedWeight(set.targetWeight))kg × \(set.targetReps)")`.

- [X] T006 [US1] In `Features/Workout/Views/Components/LogSetSheet.swift`: replace `initial.prevWeight * Double(initial.prevReps)` with `initial.targetWeight * Double(initial.targetReps)` in the `volumeDelta` computed property.

**Checkpoint**: Build compiles; `ActiveSessionView` displays exercise data from the new response shape; `workExecutionId` is accessible on the view model.

---

## Phase 4: User Story 2 — Loading and Error States (Priority: P2)

**Goal**: Verify the existing loading/error behavior in `CheckInView` / `ReadyToLiftViewModel` still works correctly with the new response type. No logic changes are required — only the type change from T001 propagates.

**Independent Test**: Simulate service failure; confirm user stays on check-in screen with error message and button re-enabled.

- [X] T007 [US2] In `BodyMetricTests/Features/ReadyToLiftViewModelTests.swift`: update any test fixture that instantiates `StartSessionResponse` / `SessionExercise` / `SessionSet` to use the new `StartWorkoutResponse` / `ExerciseBlockPlan` / `TargetSet` types with the new field names.

- [X] T008 [US2] In `BodyMetricTests/Services/WorkoutExecutionServiceTests.swift`: update the JSON fixture string to match the new response shape (`workExecutionId`, `workoutPlanName`, `totalNumberOfSets`, `exerciseBlockPlans` with `exerciseBlockPlanId`, `exerciseName`, `orderIndex`, `numberOfSets`, `targetSets` with `targetSetId`, `targetWeight`).

**Checkpoint**: Existing unit tests pass with new fixture data; loading/error paths unchanged.

---

## Phase 5: Build Verification

- [X] T009 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED; depends on T001–T008

---

## Dependencies

```
T001 (WorkoutExecutionModels — new DTOs + toWorkoutSession)
    ↓
T002 (WorkoutModels — domain model updates)
    ↓
T003 [US1] (ActiveSessionViewModel — workExecutionId + updated init)
T004 [US1] (CheckInView — navigationDestination type)  ← parallel with T003
T005 [US1] (ExerciseCard — remove muscle/PR, update SetRowView)  ← parallel with T003/T004
T006 [US1] (LogSetSheet — volumeDelta)  ← parallel with T003/T004/T005
    ↓ (all T003–T006 done)
T007 [US2] (ReadyToLiftViewModelTests — fixture update)  ← parallel with T008
T008 [US2] (WorkoutExecutionServiceTests — JSON fixture)  ← parallel with T007
    ↓
T009 (build)
```

T003, T004, T005, T006 all touch different files and can be applied simultaneously after T001 and T002.
T007 and T008 touch different test files and can be applied simultaneously.

---

## Notes

- T001: `StartSessionRequest` is unchanged — do not modify it. Only the response side changes.
- T001: `ReadyToLiftViewModel.sessionResponse` is typed as `StartSessionResponse?` — update to `StartWorkoutResponse?` as part of this task since the ViewModel owns the response type.
- T002: `PRRecord` struct can be left in the file if needed by future features, but `WorkoutExercise.pr` must be removed.
- T002: `mockToday` uses hardcoded values — set `exerciseBlockPlanId: 0` and convert string IDs to integers (e.g. `id: 1`); remove `muscle:` and `pr:` arguments; add `targetWeight:` to each `WorkoutSet`.
- T003: `ExerciseProgress(id:)` currently takes a `String` — after T002 changes `WorkoutExercise.id` to `Int`, this init must receive `Int`.
- T005: `ExerciseCard` references `exercise.pr` and `exercise.muscle` — both are removed in T002; this task removes the display code that relied on those fields.
- T006: The `volumeDelta` sign convention is unchanged — only the field names change.
