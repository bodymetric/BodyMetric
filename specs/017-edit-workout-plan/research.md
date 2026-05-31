# Research: Edit Existing Workout Plan

**Branch**: `017-edit-workout-plan`  
**Date**: 2026-05-17

---

## Decision 1: Edit vs. Create Save Strategy

**Decision**: Use a single `PUT /api/workout-plans/{id}` at wizard completion instead of reusing the step-by-step POST flow.

**Rationale**: The spec explicitly defines one update endpoint (`PUT /api/workout-plans/{id}`) that updates the full plan. Reusing the step-by-step POST flow (POST days → POST day plans per day) would create duplicate entries. A single PUT at the end is simpler, atomic, and matches the contract.

**Alternatives considered**:
- **Step-by-step updates** (`PUT` per day, `PUT` per exercise block): Requires additional endpoints not in the spec; fragile if any step fails mid-sequence.
- **Delete + recreate**: Would destroy history/IDs and violate FR-005 ("preserve existing plan ID").

---

## Decision 2: Edit Mode Entry Point — How the Plan ID Reaches the Wizard

**Decision**: `TodayViewModel.workoutPlan` (already loaded by `GET /api/home`, see feature 016) exposes `WorkoutDayPlanSummary.id: Int`. `TodayView` passes this ID to `NewPlanWizardView` as an `editPlanId: Int?` parameter when launching in edit mode.

**Rationale**: The home screen has already fetched the active plan summary (including its `id`) by the time the user opens the menu. No additional network call is needed to determine whether a plan exists or to get its ID — it's already in `TodayViewModel.loadState`.

**Alternatives considered**:
- **Re-fetch the plan ID in HomeMenuView**: Would require HomeMenuView to hold a reference to the plan ID, cluttering a pure display component.
- **Derive ID from `GET /api/workout-plans/current` inside the wizard**: This is what `loadCurrentPlan()` does — this decision is only about how to signal edit mode vs. create mode at the call site. Passing the ID in the `init` is cleaner than a global flag.

---

## Decision 3: Wizard Mode Communication — `NewPlanWizardView`

**Decision**: Add `editPlanId: Int?` parameter to `NewPlanWizardView`. When non-nil, the wizard:
1. Shows a loading state on appear while calling `NewPlanViewModel.loadCurrentPlan(using:)`.
2. Skips per-step POSTs on Continue (steps are local-only).
3. Calls `NewPlanViewModel.updatePlan(using:onSuccess:)` at Finish instead of `finish(store:)`.

**Rationale**: A single nullable init parameter keeps the call site minimal and avoids a separate `EditPlanWizardView` that would duplicate the entire wizard UI.

**Alternatives considered**:
- **Separate `EditPlanWizardView`**: Zero risk of breaking create flow but massive duplication (~250 lines of identical UI).
- **A `mode: WizardMode` enum** (`create` / `edit(planId:)`): More expressive but adds one more type; `Int?` is simpler given only two states.

---

## Decision 4: Pre-fill Timing

**Decision**: `loadCurrentPlan(using:)` runs via `.task { }` in `NewPlanWizardView.body` when `editPlanId != nil`. A new `EditPlanLoadState` (`.idle / .loading / .loaded / .failed`) is added to `NewPlanViewModel` so the wizard can gate interaction until data is ready.

**Rationale**: `.task` runs asynchronously and is tied to the view lifecycle, matching the existing pattern used by `TodayView.loadHomeData`. Gating step-1 until loading completes prevents the user from tapping Continue on an empty state.

**Alternatives considered**:
- **Preload before presenting the fullScreenCover**: Requires the parent to hold async state and a loading spinner before the wizard opens — worse UX and blurs the responsibility boundary.

---

## Decision 5: Exercise Block Pre-fill — `exerciseId` Type Mismatch

**Decision**: The wizard's `ExerciseBlock.exerciseId` is `String`; the API returns `Int`. Pre-fill converts: `exerciseId = String(currentExercise.exerciseId)`. The existing `ExerciseBlockRequest.init` already does the reverse conversion (`Int(block.exerciseId) ?? 0`), so no new bridge logic is needed.

**Rationale**: The String type in `ExerciseBlock` was inherited from the original static-catalog lookup (feature 006). Changing it to `Int` at this stage would touch all existing wizard code. A simple `String(Int)` conversion is the least-invasive approach.

**Alternatives considered**:
- **Migrate `ExerciseBlock.exerciseId` to `Int`**: Correct long-term but out-of-scope for this feature and breaks feature 012 catalog lookup paths.

---

## Decision 6: `workoutPlanIds` in Edit Mode

**Decision**: In edit mode, `workoutPlanIds[day]` is set from `GET /api/workout-plans/current` day entries (each day has its own `id`). These IDs are stored so `saveDayConfig` calls remain valid if needed, but in edit mode the Continue buttons do NOT trigger `saveDayConfig` — they just call `viewModel.advance()`.

**Rationale**: The edit save is deferred to the single PUT at Finish. Storing the per-day IDs in `workoutPlanIds` ensures no structural change to the data model.

---

## Decision 7: `GET /api/workout-plans/current` Response Shape

**Decision**: Model as `CurrentWorkoutPlan` with nested `CurrentWorkoutPlanDay`, `CurrentExerciseBlock`, and `CurrentTargetSet` structs. Field names follow the same `camelCase` convention used throughout the codebase.

**Rationale**: We cannot confirm the exact JSON keys from the spec description alone. The modelled shape follows the existing API patterns (snake_case → camelCase CodingKeys if needed, or direct camelCase if the server uses it). The decoder is configured with no special strategy; field names are matched directly.

**Unknown**: The exact JSON contract for `GET /api/workout-plans/current` and `PUT /api/workout-plans/{id}`. The models below are best-guess from the spec description and existing API patterns. They will need adjustment once the backend team confirms the contract.

---

## Decision 8: Menu ID Change — "myPlans" → "myPlan"

**Decision**: Change the menu item `id` from `"myPlans"` to `"myPlan"` and update all references in `HomeMenuView.effectiveIsActive` and `HomeMenuModels.catalog`. Add `.editPlan` to `HomeMenuDestination`.

**Rationale**: The spec requires the label to be singular ("My Plan"). The item ID is the switch key in `effectiveIsActive`; it must stay in sync with the catalog entry.
