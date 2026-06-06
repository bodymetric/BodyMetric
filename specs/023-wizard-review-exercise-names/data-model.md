# Data Model: Wizard Review Step — Correct Exercise Names

**Branch**: `023-wizard-review-exercise-names` | **Date**: 2026-05-31

## No Model Changes

This bug fix involves no data model changes. The existing types are correct.

## Relevant Existing Entities

### ExerciseBlock (existing, unchanged)

| Field | Type | Notes |
|-------|------|-------|
| exerciseId | String | Stringified integer API ID (e.g., `"26"`). Set by `ExercisePickerSheetView` via `String(ex.id)` |

### NewPlanViewModel (existing, unchanged)

| Property / Method | Type | Notes |
|-------------------|------|-------|
| `exerciseGroups` | `[ExerciseCatalogGroup]` | API catalog loaded during step 2; source of truth for exercise names |
| `exerciseName(for: String) -> String?` | Method | Converts `exerciseId` string to `Int`, looks up in `exerciseGroups` |

### Exercise.catalog (existing — NOT used after fix)

Static hardcoded list with non-integer string IDs (`"bench"`, `"squat"`, etc.). Must not be used for name resolution in the wizard.

## Source of the Bug

```
ExerciseBlock.exerciseId = "26"          (API integer string)
Exercise.catalog[i].id   = "bench"      (hardcoded slug)
→ catalog.first { $0.id == "26" } == nil
→ fallback "No exercise" always shown
```

## After Fix

```
ExerciseBlock.exerciseId = "26"
viewModel.exerciseName(for: "26")
  → Int("26") = 26
  → exerciseGroups search: id == 26 → "Bench Press"
→ "Bench Press" shown correctly
```
