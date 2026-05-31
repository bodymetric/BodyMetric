# Feature Specification: Wizard Step 2 — Persist Day Plan with Exercise Blocks

**Feature Branch**: `013-wizard-day-blocks-persist`  
**Created**: 2026-05-02  
**Status**: Draft  
**Input**: User description: "In step 2 of the Workout Plan wizard, send one POST per selected day containing the day name, order index, active flag, and all exercise blocks (each with exercise ID, order, rest time, optional flag, and target sets). Navigate through each day in sequence, advancing to the next wizard step after the last day is saved. Accept 200 or 201 as success."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Complete configuration for one day and move to the next (Priority: P1)

A user on the day configuration screen fills in the session name and adds exercise blocks for the current day. They tap Continue. The app saves the full configuration — name, exercise blocks, and each block's target sets — to the server in one operation. On success, the app moves to the configuration screen for the next selected day. This repeats until all days are configured.

**Why this priority**: This is the primary save action in the wizard. Without it, no day's configuration is persisted and the user cannot advance.

**Independent Test**: Configure one day with a session name and one exercise block, tap Continue, verify the app moves to the next day (or next wizard step if it was the last day).

**Acceptance Scenarios**:

1. **Given** the user has filled in a session name and at least one exercise block with valid target sets, **When** they tap Continue, **Then** the complete day configuration is saved in one request and the user sees the next day's configuration screen.
2. **Given** there are three selected days and the user has just saved the second, **When** the save succeeds, **Then** the user is taken to the third day's configuration screen.
3. **Given** the user is configuring the last selected day and taps Continue, **When** the save succeeds, **Then** the user advances to the next step of the wizard (beyond day configuration).

---

### User Story 2 - Exercise blocks and target sets are saved as part of the day (Priority: P2)

Each exercise block the user added — including its target sets (reps and weight) — is included in the same save operation as the day plan. The server receives a complete picture of the day in a single submission.

**Why this priority**: The exercise blocks and their targets are the core training data. Saving the day name without the exercises would create an empty plan.

**Independent Test**: Configure a day with two exercise blocks, each with multiple target sets. Tap Continue. Verify both blocks and all target sets appear correctly in the saved plan.

**Acceptance Scenarios**:

1. **Given** a day with two exercise blocks each having two target sets, **When** the user saves, **Then** all four target sets are included in the saved day configuration.
2. **Given** an exercise block with a rest period set to 90 seconds, **When** the day is saved, **Then** the rest period is preserved on the saved block.
3. **Given** an exercise block marked as optional, **When** the day is saved, **Then** the optional flag is preserved.

---

### User Story 3 - Recover gracefully from a save failure (Priority: P3)

If the save operation for a day fails (server error or no connectivity), the user sees a clear error message and stays on the current day's screen. Their configuration is preserved and they can retry.

**Why this priority**: Without error recovery, a failed save silently traps the user with no path forward.

**Independent Test**: Simulate a server failure, tap Continue on a configured day, verify the error message appears and the user stays on the same screen with their data intact.

**Acceptance Scenarios**:

1. **Given** a configured day and a network failure, **When** the user taps Continue, **Then** an error message is shown and the user remains on the current day's screen.
2. **Given** an error is shown, **When** the user taps Continue again, **Then** the save is retried with the same configuration.
3. **Given** an error is shown, **When** the user edits the configuration, **Then** the error message is dismissed.

---

### Edge Cases

- What happens if the user has no exercise blocks on a day and taps Continue? The Continue button must remain disabled until at least one exercise block with a valid exercise selected is present.
- What happens if target sets are empty for an exercise block? The form must require at least one target set per block before enabling Continue.
- What happens if the save of the first day succeeds but the save of a later day fails? Each day's save is independent; the user is shown an error for the failing day and can retry that specific day.
- What happens if the user taps Continue multiple times rapidly while a save is in progress? Only one request is sent; the button is disabled during the save.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When the user taps Continue on a day configuration screen, the app MUST submit the complete day configuration — session name, all exercise blocks, and each block's target sets — as a single save operation.
- **FR-002**: The save MUST use the workout plan identifier assigned to the current day from the previous wizard step.
- **FR-003**: Each exercise block in the save MUST include: the selected exercise, its position in the day's block list, the rest period between sets, whether the block is optional, and all configured target sets.
- **FR-004**: Each target set in the save MUST include: its position in the block's set list, the target number of repetitions, and the target weight.
- **FR-005**: On a successful save (any success response), the app MUST navigate to the configuration screen for the next selected day.
- **FR-006**: If the just-saved day was the last selected day, the app MUST advance to the next step of the wizard after the save succeeds.
- **FR-007**: If the save fails for any reason, the app MUST display a user-friendly error message and keep the user on the current day's configuration screen with all their input preserved.
- **FR-008**: The Continue button MUST be disabled while a save is in progress to prevent duplicate submissions.
- **FR-009**: The Continue button MUST be disabled until the session name is non-empty and at least one exercise block is fully configured (exercise selected, at least one target set present).

### Key Entities

- **Day Plan**: A named training session for a single day within the workout plan. Attributes: session name, position in the week (order index), active status. Contains one or more Exercise Blocks.
- **Exercise Block**: A single exercise slot within a day plan. Attributes: exercise selection, position within the day (order index), rest time between sets, optional flag. Contains one or more Target Sets.
- **Target Set**: A specific set prescription within an exercise block. Attributes: position within the block (order index), target number of repetitions, target weight.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of successful Continue taps result in the complete day configuration (name + all blocks + all target sets) being saved and the user advancing to the next day or next wizard step.
- **SC-002**: 100% of failed saves display a visible error message and keep the user on the current day screen with all configuration intact.
- **SC-003**: The Continue button is disabled in 100% of cases where the session name is blank or no exercise block is fully configured.
- **SC-004**: No duplicate save requests are sent regardless of how rapidly the user taps Continue while a save is in progress.
- **SC-005**: A user with a stable connection completes the full save for one day in under 5 seconds.

## Assumptions

- The workout plan identifier for each day is available from the step-1 response and does not need to be re-fetched.
- The server accepts both 200 and 201 as valid success responses for the day save operation.
- Exercise blocks without a selected exercise cannot be saved; the form enforces this before enabling Continue.
- Each exercise block must have at least one target set; the form enforces this before enabling Continue.
- The order index for exercise blocks is determined by their position in the user's configured list (first block = 1, second = 2, etc.).
- The order index for target sets is determined by their position within the block (first set = 1, second = 2, etc.).
- Navigation between days is automatic — the user does not manually select which day to configure next; the wizard steps through them in order.
- The optional flag defaults to false for all newly created exercise blocks unless the user explicitly marks them optional.
