# Feature Specification: Wizard Day Selection — API Integration

**Feature Branch**: `007-wizard-day-selection-api`  
**Created**: 2026-04-26  
**Status**: Draft  
**Input**: User description: "Implement the first screen of the New Plan wizard. On open, fetch existing workout-plan day selections and pre-fill checkboxes from plannedWeekNumber. 404 = no prior data, show empty form. Next requires ≥1 day selected; on Next, save selected days to the server. 201 advances to next screen; other errors show a user-friendly message."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Select days and advance to next wizard step (Priority: P1)

A user opens the first step of the New Plan wizard. The screen shows all seven weekdays as selectable options. The user taps one or more days to mark them as training days, then taps "Next". The system saves their selections and takes them to the second wizard step.

**Why this priority**: This is the screen's primary purpose — without the ability to select days and advance, the wizard cannot be completed at all.

**Independent Test**: Can be fully tested by opening the wizard with no prior data, tapping at least one day, tapping Next, and verifying the second wizard step appears.

**Acceptance Scenarios**:

1. **Given** the screen is open with no days selected, **When** the user taps one day and taps Next, **Then** the system saves the selection and the second wizard step is presented.
2. **Given** the screen is open, **When** the user taps multiple days and taps Next, **Then** all selected days are saved and the second step is presented.
3. **Given** the screen is open with no days selected, **When** the user taps Next without selecting any day, **Then** the Next button is disabled and no navigation occurs.

---

### User Story 2 - Pre-fill selections from a previous plan (Priority: P2)

A returning user who has previously set up a workout plan opens the day selection screen. The days they selected before are already checked. They can keep the selection, adjust it, and tap Next to proceed.

**Why this priority**: Pre-filling reduces friction for returning users and prevents them from accidentally losing their existing plan configuration on re-entry.

**Independent Test**: Can be fully tested by simulating a prior saved state, opening the screen, and verifying the previously selected days appear pre-checked.

**Acceptance Scenarios**:

1. **Given** the user previously saved Sunday as a training day, **When** the day selection screen opens, **Then** Sunday's checkbox is pre-selected and all others are unchecked.
2. **Given** the user previously saved Monday and Friday as training days, **When** the screen opens, **Then** both Monday and Friday are pre-selected.
3. **Given** the user has a pre-filled selection, **When** the user removes one day and taps Next, **Then** only the remaining selected days are saved.

---

### User Story 3 - Handle save failure gracefully (Priority: P3)

A user selects their training days and taps Next, but the save operation fails (due to a server error or connectivity issue). The screen remains open, and a clear error message is displayed explaining that the selection could not be saved. The user can try again.

**Why this priority**: Without graceful error handling, a save failure would silently trap the user or lose their work.

**Independent Test**: Can be tested by simulating a server error response, tapping Next, and verifying the error message appears and the user stays on the day selection screen.

**Acceptance Scenarios**:

1. **Given** the user has at least one day selected and taps Next, **When** the save request fails, **Then** an error message is displayed and the user remains on the day selection screen.
2. **Given** an error message is displayed, **When** the user taps Next again with days still selected, **Then** the system retries the save operation.
3. **Given** an error is displayed, **When** the user modifies their day selection, **Then** the error message is dismissed.

---

### Edge Cases

- What happens if the screen is opened while a previous load is still in progress? Only one load must run at a time; the screen shows a loading indicator until data is ready.
- What happens if the network is unavailable when the screen opens? The screen starts with no days pre-selected (same as empty state), allowing the user to proceed with a fresh selection.
- What happens if the user taps "Next" while the save is already in progress? The Next button is disabled while any save operation is running to prevent duplicate submissions.
- What happens if the user toggles all days off after having some pre-selected? The Next button becomes disabled; the user cannot proceed without at least one day selected.
- What happens if loading the prior selections fails for a reason other than "no data exists"? The screen shows an empty form (no days pre-selected) and the user can still make a selection and proceed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When the day selection screen opens, the system MUST attempt to load the user's previously saved training day selections before displaying the form in its final state.
- **FR-002**: While previous selections are being loaded, the screen MUST display a loading indicator so the user knows retrieval is in progress.
- **FR-003**: If the user has previously saved training day selections, the system MUST pre-check those days when the screen finishes loading.
- **FR-004**: If no prior day selections exist for the user, the system MUST display the form with all seven days unchecked.
- **FR-005**: If the load fails for any reason other than "no prior data", the system MUST display the form with all seven days unchecked, allowing the user to continue.
- **FR-006**: The screen MUST display all seven days of the week (Monday through Sunday) as individually selectable options.
- **FR-007**: The user MUST be able to tap any day to toggle it between selected and unselected.
- **FR-008**: The "Next" button MUST be disabled when no days are selected and MUST become enabled as soon as at least one day is selected.
- **FR-009**: When the user taps "Next" with at least one day selected, the system MUST send the complete list of selected days to the server for saving.
- **FR-010**: While a save operation is in progress, the Next button MUST be disabled to prevent duplicate submissions.
- **FR-011**: If the save operation succeeds, the system MUST navigate the user to the second step of the New Plan wizard.
- **FR-012**: If the save operation fails, the system MUST display a user-friendly error message on the same screen and MUST NOT navigate away.
- **FR-013**: After a save failure, the user's day selection MUST be preserved so they can retry without re-selecting days.

### Key Entities

- **Workout Plan Day**: A single planned training day. Attributes: week number (1–7, where 1 = Monday and 7 = Sunday), day name (monday–sunday). Represents one entry in the user's weekly workout plan.
- **Weekly Training Plan**: The full set of days a user intends to train each week. Composed of one or more Workout Plan Days. A plan is valid when it contains at least one day.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user with no prior data can open the screen, select at least one day, and advance to the next wizard step in under 30 seconds.
- **SC-002**: Previously saved day selections are reflected on the screen within 2 seconds of the screen opening under normal network conditions.
- **SC-003**: 100% of successful save operations result in navigation to the next wizard step with no additional user action required.
- **SC-004**: 100% of failed save operations display a visible error message and keep the user on the day selection screen with their selection intact.
- **SC-005**: The Next button is disabled in 100% of cases where no day is selected, preventing progression without a valid selection.
- **SC-006**: No duplicate save requests are sent, regardless of how many times the user taps Next while a save is in progress.

## Assumptions

- The user is authenticated before entering the wizard; attaching the session credential to outgoing requests is handled by the existing authenticated network layer and requires no changes in this feature.
- "No prior data" is a normal, expected state for first-time users and is not treated as an error.
- The save operation is a **replace** operation — it replaces all previously saved day selections with the new set (not an append or merge).
- The per-day details returned during load (such as exercise counts or session names from prior plans) are supplemental context; if present, they may be displayed on the day row for reference but do not affect the core selection behaviour and are not sent back during save.
- Navigation to the "next wizard step" refers to Step 2 of the New Plan wizard (per-day exercise configuration); the content of that step is out of scope for this feature.
- Any non-success response from the server during save is treated uniformly as a failure; the feature does not distinguish between different server-side error codes.
- Network timeout and connectivity errors during save are treated the same as server errors — the user sees an error message and can retry.
