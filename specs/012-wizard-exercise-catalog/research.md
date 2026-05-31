# Research: Wizard Step 2 — Live Exercise Catalog

**Date**: 2026-05-01

---

## 1. ExerciseBlock.exerciseId stays as String

**Decision**: Keep `ExerciseBlock.exerciseId: String` but store the integer as a string (e.g., `"26"`). Convert to `Int` only when building the POST request body.

**Rationale**: `ExerciseBlock` is `Codable` and stored in `WorkoutPlan` (UserDefaults). Changing the field type to `Int` would require a migration. Keeping it as `String` is backward-compatible. When converting to `ExerciseBlockPlanRequest`, parse `Int(exerciseId) ?? 0`.

**Alternatives considered**:
- Change `exerciseId` to `Int` everywhere — rejected; touches too many files and breaks stored plans.

---

## 2. ExerciseBlockPlanRequest.exerciseId changes to Int

**Decision**: Change `ExerciseBlockPlanRequest.exerciseId` from `String` to `Int`. The server returns integer exercise IDs and almost certainly expects integers in the POST body.

**Rationale**: API contract consistency. Sending `"26"` (string) when the server expects `26` (int) would likely cause a 400 error.

**Fix**: `ExerciseBlockPlanRequest.init(block:)` converts `Int(block.exerciseId) ?? 0`.

---

## 3. Catalog owned by NewPlanViewModel

**Decision**: `NewPlanViewModel` owns `var exerciseGroups: [ExerciseCatalogGroup] = []` and `var exerciseCatalogLoadState: ExerciseCatalogLoadState`. The load method `loadExerciseCatalog(using:)` guards `exerciseGroups.isEmpty` so it runs only once per wizard session.

**Rationale**: The wizard may show multiple day-config steps (one per selected day). Owning the catalog in the ViewModel ensures all steps share the same result without any additional plumbing.

**Alternatives considered**:
- Load in `ConfigureDayStepView` local state — rejected; each step would independently manage the state.
- Load in `NewPlanWizardView` — acceptable but adds catalog state to the root view unnecessarily.

---

## 4. ExercisePickerSheetView accepts catalog as parameter

**Decision**: Add `let exerciseCatalog: [ExerciseCatalogGroup]` parameter to `ExercisePickerSheetView`. Remove the static `Exercise.catalog` dependency.

**Rationale**: The picker is a leaf view; injecting the catalog via parameter keeps it pure and testable. The parent (`ConfigureDayStepView`) obtains the catalog from the ViewModel.

---

## 5. ExerciseBlockRowView accepts exerciseName parameter

**Decision**: Add `exerciseName: String?` parameter to `ExerciseBlockRowView`. Remove the `Exercise.catalog.first { $0.id == block.exerciseId }` lookup.

**Rationale**: After migration to integer IDs, the static catalog's string IDs won't match the new numeric IDs stored in `exerciseId`. The parent computes the name from the ViewModel's API catalog.

**Name lookup**: `viewModel.exerciseName(for: block.exerciseId)` — a helper that searches `exerciseGroups` for an exercise whose `id == Int(block.exerciseId)`.

---

## 6. Loading state enum

```swift
enum ExerciseCatalogLoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
}
```

**Behaviour**:
- `idle` → loading not yet started
- `loading` → request in flight; picker shows skeleton/spinner
- `loaded` → `exerciseGroups` populated; pickers show exercises
- `failed(message)` → error shown with retry option

---

## 7. Retry mechanism

**Decision**: `ConfigureDayStepView` shows an error banner with a "Retry" button when `exerciseCatalogLoadState == .failed`. Tapping retry calls `viewModel.loadExerciseCatalog(using:)` again (force re-fetch by clearing `exerciseGroups` first).

---

## All NEEDS CLARIFICATION Items

None — all decisions resolved.
