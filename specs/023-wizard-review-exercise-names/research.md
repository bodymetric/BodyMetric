# Research: Wizard Review Step — Correct Exercise Names

**Branch**: `023-wizard-review-exercise-names` | **Date**: 2026-05-31

## Root Cause

`ReviewStepView.blockSummaryRow` (line 150) resolves exercise names from `Exercise.catalog` — a static, hardcoded list of exercises with **string IDs** like `"bench"`, `"squat"`, `"curl"`. However, `ExerciseBlock.exerciseId` stores the **stringified integer IDs** from the server API (e.g., `"26"`, `"17"`). These IDs never match the static catalog, so `exercise` is always `nil` and the fallback `"No exercise"` is always shown.

```swift
// Current (broken) — ReviewStepView.swift line 150
let exercise = Exercise.catalog.first { $0.id == block.exerciseId }
// Exercise.catalog IDs: "bench", "squat", "curl", ...
// block.exerciseId values: "26", "17", "42", ...
// → never matches → exercise == nil → shows "No exercise"
```

## Finding: Correct Lookup Method Already Exists

`NewPlanViewModel` already has `exerciseName(for: String) -> String?` (line 243) which searches the API-loaded catalog:

```swift
func exerciseName(for exerciseId: String) -> String? {
    guard let id = Int(exerciseId) else { return nil }
    return exerciseGroups.flatMap(\.exercises).first { $0.id == id }?.name
}
```

`ReviewStepView` already holds `@Bindable var viewModel: NewPlanViewModel` — no new injection needed.

`ConfigureDayStepView` already uses `viewModel.exerciseName(for: block.exerciseId)` correctly for step 2. The review step just missed this pattern.

---

## Decision: Use `viewModel.exerciseName(for:)` in `blockSummaryRow`

**Change**: Replace lines 150–156 in `ReviewStepView.swift`:

```swift
// Before
let exercise = Exercise.catalog.first { $0.id == block.exerciseId }
// ...
Text(exercise?.name ?? "No exercise")

// After
Text(viewModel.exerciseName(for: block.exerciseId) ?? "No exercise")
```

**Rationale**: `viewModel.exerciseName(for:)` is the single source of truth for exercise names in the wizard. It searches `exerciseGroups` (populated from the API during step 2). This is the same pattern used by `ConfigureDayStepView`.

**Alternatives considered**:
- Updating `Exercise.catalog` to use integer string IDs — rejected; the static catalog is a legacy artifact that should not be extended
- Adding a name cache to `ExerciseBlock` — rejected; adding denormalized state to the model is unnecessary when the viewmodel already provides the lookup

---

## Scope

| File | Change |
|------|--------|
| `Features/NewPlan/Views/Components/ReviewStepView.swift` | Remove `let exercise = Exercise.catalog...` line; change `Text(exercise?.name ?? ...)` to `Text(viewModel.exerciseName(for: block.exerciseId) ?? ...)` |

No other files need to change. Net diff: −1 line, ~1 line modified.
