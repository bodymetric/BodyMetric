# Research: Remove "Plan Another Week" Button

**Branch**: `024-remove-plan-another-week` | **Date**: 2026-05-31

## Decision Log

### Decision 1 — Remove `onRestart` callback entirely

**Decision**: Remove the `onRestart: () -> Void` parameter from `PlanSavedView` along with the button.

**Rationale**: The callback only resets the wizard's `viewModel` to a fresh `NewPlanViewModel()`. With the button gone there are no remaining callers, so keeping a dead parameter would be misleading.

**Alternatives considered**:
- Keep the parameter as a no-op default (`onRestart: () -> Void = {}`): rejected — dead code with no callers is worse than removing it cleanly.

### Decision 2 — No new tests required

**Decision**: No new unit tests are needed beyond build verification.

**Rationale**: This is a pure UI removal. The view loses a button and a callback parameter; there is no business logic introduced or changed. The existing test suite (if any) for `PlanSavedView` should be updated to remove any reference to `onRestart`.

**Alternatives considered**: Adding a snapshot or accessibility test to assert the button is absent — unnecessary overhead for a one-line removal.

## Files Affected

| File | Change |
|------|--------|
| `Features/NewPlan/Views/Components/PlanSavedView.swift` | Remove `onRestart` property, `actionButtons` button, update doc comment |
| `Features/NewPlan/Views/NewPlanWizardView.swift` | Remove `onRestart:` argument from `PlanSavedView(...)` call |
