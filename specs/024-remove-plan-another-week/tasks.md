# Tasks: Remove "Plan Another Week" Button

**Input**: Design documents from `/specs/024-remove-plan-another-week/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ quickstart.md ✅

**Scope**: 2 source files modified (~10 lines removed). No new files.

---

## Phase 1: Setup

No new directories, packages, or project files required.

---

## Phase 2: User Story 1 — Success Screen Shows Only "Back to Home" (Priority: P1) 🎯

**Goal**: Remove the "Plan another week" `Button` and the `onRestart: () -> Void` property from `PlanSavedView`, then remove the `onRestart:` argument from its call site in `NewPlanWizardView`.

**Independent Test**: Open `PlanSavedView` with only `dayCount` and `onHome`; assert it compiles and the "Plan another week" text is absent.

- [X] T001 [US1] In `Features/NewPlan/Views/Components/PlanSavedView.swift`: remove `let onRestart: () -> Void` property (line 13), remove the entire `Button(action: onRestart) { ... }` block from `actionButtons` (lines 128–135), and update the doc comment on line 5 to remove the `onRestart()` reference.

- [X] T002 [US1] In `Features/NewPlan/Views/NewPlanWizardView.swift`: remove the `onRestart: { [self] in viewModel = NewPlanViewModel() }` argument from the `PlanSavedView(...)` initializer call (lines 54–60).

**Checkpoint**: `PlanSavedView` takes only `dayCount` and `onHome`; the success screen shows a single "Back to home" button.

---

## Phase 3: Build Verification

- [X] T003 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED; depends on T001–T002

---

## Dependencies

```
T001 [US1] (PlanSavedView — remove button + property)
    ↓
T002 [US1] (NewPlanWizardView — remove call-site argument)
    ↓
T003 (build)
```

T001 must precede T002 because T002's change is only valid after `onRestart` is removed from the struct (otherwise the build would fail at the call site before the property is gone). In practice both changes can be applied before building, but T001 logically precedes T002.

---

## Notes

- T001: The `actionButtons` computed property currently wraps both buttons in a `VStack(spacing: 8)`. After removing the second button, the `VStack` can be replaced with a plain `Button` — or left as a single-item `VStack`. Either compiles; remove the `VStack` for cleanliness.
- T002: After removing `onRestart:`, the trailing comma after `onHome: { dismiss() }` (if present) must also be removed to keep valid Swift syntax.
- T003: No test changes needed — this is a pure removal with no logic added.
