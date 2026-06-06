# Feature Specification: Remove "Plan Another Week" Button

**Feature Branch**: `024-remove-plan-another-week`
**Created**: 2026-05-31
**Status**: Draft
**Input**: Remove the "Plan another week" button from the wizard success screen (PlanSavedView)

## User Scenarios & Testing

### User Story 1 — Success Screen Shows Only "Back to Home" (Priority: P1)

After creating or editing a workout plan and seeing the "Plan saved" success screen, the user sees a single action button: "Back to home". The "Plan another week" button is gone.

**Why this priority**: The button is being removed — this is the entire scope of the change.

**Independent Test**: Open `PlanSavedView` in isolation; assert it contains a "Back to home" button and no "Plan another week" button.

**Acceptance Scenarios**:

1. **Given** the wizard has completed and `PlanSavedView` is presented, **When** the user views the success screen, **Then** only the "Back to home" button is visible.
2. **Given** `PlanSavedView` is presented, **When** the user taps "Back to home", **Then** `onHome()` is called and the wizard is dismissed.
3. **Given** `PlanSavedView` is presented, **When** the user views the screen, **Then** no "Plan another week" button exists anywhere on the screen.

---

### Edge Cases

- No edge cases: this is a pure removal with no behavior change to the remaining button.

## Requirements

### Functional Requirements

- **FR-001**: `PlanSavedView` MUST NOT display a "Plan another week" button.
- **FR-002**: `PlanSavedView` MUST still display the "Back to home" button with unchanged behavior.
- **FR-003**: The `onRestart` callback parameter MUST be removed from `PlanSavedView`'s initializer.
- **FR-004**: All call sites of `PlanSavedView` MUST be updated to remove the `onRestart` argument.

### Key Entities

- **PlanSavedView**: The wizard success screen; loses the `onRestart: () -> Void` property and its associated button.

## Success Criteria

### Measurable Outcomes

- **SC-001**: `PlanSavedView` compiles without the `onRestart` parameter.
- **SC-002**: Build succeeds with zero errors after the change.
- **SC-003**: The "Back to home" button continues to work as before.

## Assumptions

- The `onRestart` callback (which reset `viewModel = NewPlanViewModel()`) is no longer needed; users who want to create another plan can navigate back to the home screen and open the wizard again.
- No other screens reference `PlanSavedView.onRestart`.
