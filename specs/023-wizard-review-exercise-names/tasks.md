# Tasks: Wizard Review Step — Correct Exercise Names

**Input**: Design documents from `/specs/023-wizard-review-exercise-names/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ quickstart.md ✅

**Scope**: 1 source file modified (2 lines), 1 test file updated (2 tests added). No new files.

---

## Phase 1: Setup

No new directories, packages, or project files required.

---

## Phase 2: User Story 1 — Review Screen Shows Correct Exercise Names (Priority: P1) 🎯

**Goal**: Replace the static `Exercise.catalog` lookup with `viewModel.exerciseName(for: block.exerciseId)` in `ReviewStepView.blockSummaryRow` so exercise names are resolved from the API catalog.

**Independent Test**: Set `viewModel.exerciseGroups` with a known exercise (`id: 26, name: "Bench Press"`), set `block.exerciseId = "26"`, assert `viewModel.exerciseName(for: "26") == "Bench Press"`.

- [X] T001 [US1] In `BodyMetricTests/Features/NewPlanViewModelTests.swift`: tests already exist (`test_exerciseName_returnsCorrectName` at line 665 covers valid ID, nil, and empty cases) — no new tests needed

- [X] T002 [US1] In `Features/NewPlan/Views/Components/ReviewStepView.swift` (method `blockSummaryRow`, lines ~149–166): remove the line `let exercise = Exercise.catalog.first { $0.id == block.exerciseId }` and change `Text(exercise?.name ?? "No exercise")` to `Text(viewModel.exerciseName(for: block.exerciseId) ?? "No exercise")`

**Checkpoint**: Review step displays actual exercise names; blocks without a selected exercise still show "No exercise".

---

## Phase 3: Build Verification

- [X] T003 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED; depends on T001–T002

---

## Dependencies

```
T001 [US1] (tests — write first per TDD)
    ↓
T002 [US1] (implementation)
    ↓
T003 (build)
```

T001 and T002 touch different files but T002 should be implemented after T001 per TDD convention.

---

## Notes

- T001: Check `NewPlanViewModelTests.swift` for existing `exerciseName` tests first — add only if missing. The `MockExerciseCatalogGroup` / `ExerciseCatalogGroup` fixtures may already exist in the file; reuse them if so.
- T002: The `viewModel` property (`@Bindable var viewModel: NewPlanViewModel`) is already present in `ReviewStepView` — no injection change needed. The only change is inside `blockSummaryRow`.
- T003: The `Exercise.catalog` reference is removed entirely from `blockSummaryRow`; no other callers of `Exercise.catalog` in the wizard are affected.
