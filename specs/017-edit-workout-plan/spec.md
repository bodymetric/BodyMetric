# Feature Specification: Edit Existing Workout Plan

**Feature Branch**: `017-edit-workout-plan`  
**Created**: 2026-05-17  
**Status**: Draft  
**Input**: User description: "Users with an existing current workout plan must be able to edit their plan through the menu item My Plan."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Open Existing Plan in Edit Mode (Priority: P1)

A user with an active workout plan taps "My Plan" in the home menu and sees the wizard open pre-filled with all their existing plan data — training days, day names, exercises, sets, reps, weight, and rest time. Every field is editable.

**Why this priority**: This is the entry point for the entire feature. Without the ability to load and display the existing plan in the wizard, no editing is possible. Delivers the minimum viable read-in value.

**Independent Test**: Can be fully tested by tapping "My Plan" while an active plan exists and verifying all wizard fields are pre-populated with the correct data from the plan.

**Acceptance Scenarios**:

1. **Given** the user has an active workout plan, **When** they tap "My Plan" in the menu, **Then** the wizard opens in edit mode with all existing plan data pre-filled (selected days, day names, exercises, sets, reps, weight, rest time).
2. **Given** the user has no active workout plan, **When** they view the menu, **Then** "My Plan" is hidden or disabled and "New Workout Plan" remains enabled.
3. **Given** the wizard is loading the existing plan, **When** data is being fetched, **Then** a loading/skeleton state is shown and interaction is prevented until loading completes.

---

### User Story 2 - Edit and Save Plan Changes (Priority: P2)

A user modifies their existing workout plan — changing exercises, sets, reps, weight, rest time, day names, or selected weekdays — and saves the changes. The backend updates the existing plan rather than creating a duplicate.

**Why this priority**: Editing and persisting changes is the core purpose of the feature. Depends on US1 (loading data) being complete.

**Independent Test**: Can be tested by loading an existing plan, modifying at least one field, saving, and verifying the same plan ID is preserved and the backend shows the updated data.

**Acceptance Scenarios**:

1. **Given** the wizard is open in edit mode with existing data, **When** the user changes any field and completes the wizard, **Then** the backend receives an update request that preserves the existing plan ID.
2. **Given** the user modifies exercises (adds, removes, or reorders), **When** they save, **Then** the updated exercise list with correct ordering is persisted.
3. **Given** the user changes selected training weekdays, **When** they save, **Then** the updated day selection is persisted.
4. **Given** the user modifies set details (reps, weight, rest time), **When** they save, **Then** the updated set prescriptions are persisted.
5. **Given** the user saves successfully, **When** returning to the home screen, **Then** the home screen reflects the updated plan data.

---

### User Story 3 - Menu Item Naming and Availability (Priority: P3)

The home menu displays "My Plan" (singular) instead of "My Plans", and the item is only interactive when the user has an active plan. When no active plan exists, the item is hidden or visually disabled.

**Why this priority**: UI polish and discoverability — important for consistency but non-blocking since it only touches the menu label and conditional rendering.

**Independent Test**: Can be tested independently by toggling between a user state with and without an active plan and verifying the menu label and availability state.

**Acceptance Scenarios**:

1. **Given** any authenticated user views the menu, **When** the menu is open, **Then** the menu item is labeled "My Plan" (not "My Plans").
2. **Given** the user has an active plan, **When** the menu is open, **Then** "My Plan" is enabled and tappable.
3. **Given** the user has no active plan, **When** the menu is open, **Then** "My Plan" is hidden or disabled (not interactive).

---

### Edge Cases

- What happens when the plan fetch fails mid-load (network error or server error)?
- What happens when the save request fails after the user finishes editing?
- What happens when an exercise from the existing plan no longer exists in the catalog?
- What happens when the user removes all exercises from a training day before saving?
- What happens when the user dismisses the wizard without saving?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST fetch the authenticated user's current active workout plan via `GET /api/workout-plans/current`, including a valid Bearer authorization token, on wizard initialization.
- **FR-002**: System MUST pre-fill all wizard fields with the fetched plan data: selected training days, day plan names, exercises (including order), target sets, target reps, target weight, and rest time.
- **FR-003**: Users MUST be able to edit all pre-filled fields: add/remove/reorder exercises, add/remove sets, edit reps/weight/rest time, rename training days, and change selected weekdays.
- **FR-004**: System MUST display a skeleton or loading state while the existing plan is being fetched and MUST prevent user interaction until data is fully loaded.
- **FR-005**: System MUST submit plan updates via `PUT /api/workout-plans/{id}`, using the existing plan's server-assigned ID to update the existing record rather than creating a new plan.
- **FR-006**: System MUST display "My Plan" (singular) as the menu item label.
- **FR-007**: System MUST enable the "My Plan" menu item only when the user has a current active workout plan; when no active plan exists, the item MUST be hidden or non-interactive.
- **FR-008**: System MUST preserve the user-defined exercise ordering within each training day when saving.
- **FR-009**: System MUST preserve the user-defined set ordering within each exercise block when saving.
- **FR-010**: The "New Workout Plan" menu item MUST remain enabled regardless of whether an active plan exists.
- **FR-011**: System MUST show an error state and allow retry if the plan fetch fails during wizard initialization.
- **FR-012**: System MUST show an error state and allow retry if the save request fails during wizard completion.

### Key Entities

- **WorkoutPlan**: The user's overall training plan, identified by a server-assigned ID, containing a name and a collection of workout day plans.
- **WorkoutDayPlan**: A single day's training configuration, identified by day of week and a user-given name, containing an ordered list of exercise blocks.
- **ExerciseBlock**: A specific exercise assigned to a day, with an order index and a list of target sets.
- **TargetSet**: A prescription of reps, weight, and rest time for one set within an exercise block, with an order index.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can open their existing workout plan in edit mode in under 3 seconds on a standard mobile connection.
- **SC-002**: All existing plan data — training days, exercises, sets, and set details — is correctly pre-filled with 100% accuracy on load.
- **SC-003**: Users can complete a full plan edit (change at least one exercise and one set) and save in under 5 minutes.
- **SC-004**: Saving a plan update preserves the existing plan ID in 100% of cases — zero duplicate plans are created.
- **SC-005**: The "My Plan" menu item correctly reflects availability in 100% of cases: tappable when an active plan exists, hidden or disabled when it does not.

## Assumptions

- The authenticated user has at most one current active workout plan at a time; this feature targets that single plan.
- The `GET /api/workout-plans/current` endpoint returns all data needed to fully populate the wizard, including nested day plans, exercise blocks, and set prescriptions with ordering.
- The `PUT /api/workout-plans/{id}` endpoint accepts a full updated plan payload in the same structure used for plan creation.
- The existing wizard UI (from features 011–013) is the edit surface; this feature reuses it in pre-filled mode rather than building a new UI.
- Exercises from the existing plan that may have been removed from the catalog can still be displayed and edited within the wizard.
- Discarding changes (dismissing wizard without saving) leaves the existing plan unchanged.
- The home screen data (feature 015/016) already exposes whether the user has an active plan (`hasActivePlan`), enabling menu item conditional availability without an additional API call.
