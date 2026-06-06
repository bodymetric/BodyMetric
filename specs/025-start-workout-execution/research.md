# Research: Start Workout Execution

**Branch**: `025-start-workout-execution` | **Date**: 2026-05-31

## Decision Log

### Decision 1 — Replace `StartSessionResponse` and all sub-DTOs entirely

**Decision**: Delete the old `StartSessionResponse`, `SessionExercise`, `SessionSet` structs in `WorkoutExecutionModels.swift` and replace them with `StartWorkoutResponse`, `ExerciseBlockPlan`, `TargetSet` that exactly match the new API contract.

**Rationale**: The old and new API shapes are incompatible — field names, nesting, and cardinality all differ. Trying to add properties to the old structs would leave dead code and create confusion. A clean replacement is safer and easier to test.

**Alternatives considered**: Rename fields via `CodingKeys` — rejected because the structural differences (not just name differences) make this approach more complex than a clean rewrite.

---

### Decision 2 — Update `WorkoutSet` and `SetProgress` to use `targetWeight` instead of `prevWeight`/`prevReps`

**Decision**: Replace `WorkoutSet.prevWeight: Double` and `WorkoutSet.prevReps: Int` with `WorkoutSet.targetWeight: Double`. Update `SetProgress` to mirror this change.

**Rationale**: The new API provides `targetWeight` per set (the weight the plan prescribes). The previous best (`prevWeight`, `prevReps`) are not returned. The workout log sheet can still pre-fill weight with `targetWeight` and reps with `targetReps`.

**Alternatives considered**: Make `prevWeight`/`prevReps` optional — rejected because they would always be nil with the new API, making them misleading dead fields.

---

### Decision 3 — Remove `muscle` and `pr` from `WorkoutExercise`; update `ExerciseCard` display

**Decision**: Remove `WorkoutExercise.muscle: String` and `WorkoutExercise.pr: PRRecord?` because the new API does not return them. The `ExerciseCard` subtitle (currently `"\(doneCount)/\(total) sets · \(muscle)"`) is simplified to `"\(doneCount)/\(total) sets"`. The PR badge is removed.

**Rationale**: Showing nil or empty data causes confusion. Removing these fields now is cleaner than patching them later. The PR feature can be re-added in a separate spec when the API supports it.

**Alternatives considered**: Hardcode an empty string for muscle — rejected; would leave dead UI.

---

### Decision 4 — Add `workExecutionId` to `ActiveSessionViewModel`

**Decision**: Add `let workExecutionId: Int` to `ActiveSessionViewModel`. Passed from `CheckInView` via the init.

**Rationale**: The spec requires the active screen to retain `workExecutionId` for future progress-saving calls. Storing it in the ViewModel is the correct place since it lives for the session's lifetime.

---

### Decision 5 — Mood is carried from `CheckInView` state, not from the server response

**Decision**: The new API response does not include `feeling`. The `CheckInView` already holds the selected `mood: Mood?`. Pass `mood?.rawValue.uppercased() ?? ""` to `ActiveSessionViewModel(mood:)` when constructing it in `navigationDestination`.

**Rationale**: The old code used `response.feeling` which no longer exists. The mood selection is already in view state; using it directly is simpler than adding it back to the response.

---

### Decision 6 — `StartWorkoutResponse` must remain `Hashable` for `NavigationPath`

**Decision**: Conform `StartWorkoutResponse` to both `Decodable` and `Hashable` so it can be pushed onto the `NavigationPath` in `CheckInView`.

**Rationale**: `CheckInView` uses `.navigationDestination(for: StartWorkoutResponse.self)` driven by `path.append(response)`. `NavigationPath` requires `Hashable`. This is the existing pattern — no change to navigation mechanism.

---

### Decision 7 — Add `exerciseBlockPlanId` to `WorkoutExercise` as `Int`

**Decision**: Add `let exerciseBlockPlanId: Int` to `WorkoutExercise`. The `toWorkoutSession()` mapping sets it from `ExerciseBlockPlan.exerciseBlockPlanId`.

**Rationale**: The spec requires the active screen to retain block IDs for future progress saving. Adding the field now prevents a follow-up model change later.

---

## Files to Modify

| File | Scope of Change |
|------|----------------|
| `Models/WorkoutExecutionModels.swift` | Replace `StartSessionResponse`, `SessionExercise`, `SessionSet`; update `toWorkoutSession()` |
| `Features/Workout/Models/WorkoutModels.swift` | Update `WorkoutExercise` (add `exerciseBlockPlanId`, remove `muscle`, `pr`); update `WorkoutSet` (`targetWeight` replaces `prevWeight`/`prevReps`); update `SetProgress`; update `mockToday` |
| `Features/Workout/ViewModels/ActiveSessionViewModel.swift` | Add `workExecutionId: Int`; update init progress mapping (use `targetWeight`) |
| `Features/Workout/Views/CheckInView.swift` | Update `navigationDestination` type to `StartWorkoutResponse`; pass mood from view state; pass `workExecutionId` |
| `Features/Workout/Views/Components/ExerciseCard.swift` | Remove `muscle` subtitle suffix; remove PR badge block |
| `Features/Workout/Views/Components/LogSetSheet.swift` | Replace `prevWeight * prevReps` with `targetWeight * targetReps` in `volumeDelta` |
| `BodyMetricTests/Services/WorkoutExecutionServiceTests.swift` | Update test fixtures for new response shape |
| `BodyMetricTests/Features/ReadyToLiftViewModelTests.swift` | Update test fixtures for new response shape |
