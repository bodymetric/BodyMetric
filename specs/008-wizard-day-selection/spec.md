# Feature Specification: New Plan Wizard — Day Selection Screen

**Feature Branch**: `008-wizard-day-selection`  
**Created**: 2026-04-26  
**Status**: Draft  
**Input**: User description: "When the first screen of new plan opens: fetch existing plan data with Bearer token to pre-fill day checkboxes (plannedWeekNumber 1–7, where 7 = Sunday). 404 means empty form. On Next with valid selection POST selected days; 201 advances to next screen, other status shows error."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Select training days and advance to the next wizard step (Priority: P1)

A user opens the first screen of the New Plan wizard. All seven weekdays are displayed as selectable options. The user taps one or more days to mark them as training days, then taps "Next". The system saves the selection and takes the user to the second wizard step.

**Why this priority**: This is the screen's core purpose. Without the ability to select days and proceed, the entire wizard is blocked.

**Independent Test**: Open the wizard with no prior data, tap at least one day, tap Next, and verify the second wizard step appears.

**Acceptance Scenarios**:

1. **Given** the screen is open with no days selected, **When** the user selects one day and taps Next, **Then** the selection is saved and the second wizard step is presented.
2. **Given** the screen is open, **When** the user selects multiple days and taps Next, **Then** all selected days are saved and the second step is presented.
3. **Given** the screen is open with no days selected, **When** the user taps Next, **Then** the Next button is disabled and no navigation occurs.

---

### User Story 2 - See previously saved day selections on re-entry (Priority: P2)

A returning user who has already been through this wizard step opens the day selection screen again. The days they saved previously are pre-checked. They can keep, add, or remove days and tap Next to proceed.

**Why this priority**: Pre-filling from existing data reduces user effort on re-entry and prevents accidental loss of prior configuration.

**Independent Test**: Simulate a prior saved state with Sunday selected, open the screen, and verify Sunday's checkbox is pre-checked while all other days are unchecked.

**Acceptance Scenarios**:

1. **Given** the user previously saved Sunday as a training day, **When** the day selection screen opens, **Then** Sunday is pre-checked and all other days are unchecked.
2. **Given** the user previously saved Monday and Friday, **When** the screen opens, **Then** Monday and Friday are pre-checked.
3. **Given** the user has pre-filled days, **When** the user removes one day and taps Next, **Then** only the remaining selected days are saved.
4. **Given** the user has never set up a plan before, **When** the screen opens, **Then** all seven days appear unchecked.

---

### User Story 3 - Recover from a failed save (Priority: P3)

A user selects training days and taps Next, but the save operation fails. The screen stays open, the user's selection is preserved, and a clear error message explains that saving failed. The user can try again.

**Why this priority**: Without error handling, a failed save silently traps the user with no path forward.

**Independent Test**: Simulate a server-error response on save, tap Next, verify the error banner appears and the user remains on the day selection screen with their checkboxes intact.

**Acceptance Scenarios**:

1. **Given** the user has at least one day selected and taps Next, **When** the save request fails, **Then** an error message is shown and the user remains on the day selection screen.
2. **Given** an error is shown, **When** the user taps Next again with the same selection, **Then** the system retries the save operation.
3. **Given** an error is shown, **When** the user changes the day selection, **Then** the error message is dismissed.

---

### Edge Cases

- What happens if the screen loads while a prior data fetch is already running? Only one fetch must run at a time; the screen shows a loading indicator until the fetch completes.
- What happens if all days are deselected after being pre-filled? The Next button becomes disabled; the user cannot proceed without at least one day selected.
- What happens if the data fetch fails for a reason other than "no prior data"? The screen shows an empty form (all days unchecked) and the user can still make a selection and proceed normally.
- What happens if the user taps Next repeatedly while a save is in progress? The Next button is disabled during the save to prevent duplicate submissions.
- What happens if the device loses network connectivity before the save completes? The save fails and the error state is shown, with the user's selection intact.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When the day selection screen opens, the system MUST attempt to load any previously saved training day selections before displaying the form in its final state.
- **FR-002**: While previous selections are loading, the screen MUST show a loading indicator.
- **FR-003**: If the user has previously saved day selections, the system MUST pre-check those days when the screen finishes loading.
- **FR-004**: If no prior selections exist for the user, the system MUST display the form with all seven days unchecked.
- **FR-005**: If the load fails for any reason other than "no prior data", the system MUST display the form with all seven days unchecked so the user can still proceed.
- **FR-006**: The screen MUST display all seven days of the week (Monday through Sunday) as individually toggleable options.
- **FR-007**: The user MUST be able to tap any day to toggle it between selected and unselected.
- **FR-008**: The Next button MUST be disabled when zero days are selected and MUST become enabled as soon as at least one day is selected.
- **FR-009**: When the user taps Next with at least one day selected, the system MUST submit the complete set of currently selected days for saving.
- **FR-010**: While the save operation is in progress, the Next button MUST be disabled to prevent duplicate submissions.
- **FR-011**: If the save succeeds, the system MUST navigate the user to the second step of the New Plan wizard without any additional user action.
- **FR-012**: If the save fails, the system MUST display a user-friendly error message on the same screen and MUST NOT navigate away.
- **FR-013**: After a save failure, the user's day selection MUST be fully preserved so they can retry without re-selecting.

### Key Entities

- **Workout Plan Day**: A single planned training day in the user's weekly schedule. Attributes: week number (1 = Monday … 7 = Sunday), day name (monday–sunday). Represents one day the user intends to train each week.
- **Weekly Training Plan**: The complete set of days a user intends to train per week. Composed of one or more Workout Plan Days. Valid when it contains at least one day.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A first-time user can open the screen, select at least one day, and advance to the next step in under 30 seconds.
- **SC-002**: Previously saved day selections appear on screen within 2 seconds of opening under normal network conditions.
- **SC-003**: 100% of successful saves result in automatic navigation to the next wizard step.
- **SC-004**: 100% of failed saves display a visible error message while keeping the user on the day selection screen with their selection intact.
- **SC-005**: The Next button is disabled in 100% of cases where zero days are selected.
- **SC-006**: Zero duplicate save requests are sent regardless of how rapidly the user taps Next while a save is already running.

## Assumptions

- The user is authenticated before entering the wizard; attaching the session credential to outgoing requests is handled by the existing authenticated network layer and requires no changes in this feature.
- "No prior data" is a normal, expected state for first-time users and is not treated as an error.
- The save operation is a **replace** (not append) — it replaces all previously saved day selections with the newly submitted set.
- Additional fields in the loaded data (such as session names or exercise counts from prior plans) are supplemental context; they do not affect the day-selection logic and are not submitted in the save request.
- "Next screen" refers to Step 2 of the New Plan wizard (per-day exercise configuration); what that step contains is out of scope here.
- Any non-success server response during save is treated uniformly as a failure; the feature does not show different messages for different error codes.
- Network timeout and connectivity errors during save are handled identically to server errors.
