# Feature Specification: Workout Plan Wizard — Step 2 Day & Exercise Persistence

**Feature Branch**: `011-wizard-day-persist`  
**Created**: 2026-04-29  
**Status**: Draft  
**Input**: User description: "Implement the second step of the Workout Plan wizard. Persist the WorkoutDayPlan (name, orderIndex, isActive) linked to the WorkoutPlan from step 1, then persist each ExerciseBlockPlan linked to that day. Only advance on full success; show error and remain on screen on any failure."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Name a training day, add exercises, and save to advance (Priority: P1)

A user is on the second step of the New Plan wizard. They see a form for the current training day. They enter a name for the session (e.g., "Chest and Triceps"), add one or more exercises with their target sets, reps, and rest periods, and tap Continue. The app saves the day configuration and all exercise blocks to their plan. On success, the wizard advances to the next step.

**Why this priority**: Without saving the day configuration, the workout plan is incomplete and unusable. This is the screen's entire purpose.

**Independent Test**: Open the wizard's second step, fill in a day name, add at least one exercise block, tap Continue, and verify: (1) the wizard advances to the next step, (2) the saved day is later visible in the user's workout plan.

**Acceptance Scenarios**:

1. **Given** the user has filled in a day name and added at least one exercise block, **When** they tap Continue, **Then** the day configuration and all exercise blocks are saved and the wizard advances to the next step.
2. **Given** a multi-day plan (e.g., 3 days were selected in step 1), **When** the user saves each day's configuration one by one, **Then** each day is saved independently and the wizard advances through each day in sequence.
3. **Given** the user has completed the last day in the sequence, **When** they tap Continue on that day, **Then** after saving, the wizard advances to the final review or completion step.

---

### User Story 2 - Recover from a save failure on any part of the configuration (Priority: P2)

A user has filled in their training day name and exercises and taps Continue, but the save operation fails (due to a server error or connectivity issue). The wizard stays on the same step, an error message is displayed, and the user's inputs are preserved so they can retry without re-entering data.

**Why this priority**: Without graceful error handling, a save failure would either silently advance the wizard with unsaved data or lose the user's input — both are unacceptable.

**Independent Test**: Simulate a server failure during save, tap Continue with valid data, and verify: (1) the wizard stays on step 2, (2) an error message is shown, (3) all entered data (day name and exercise blocks) is still present.

**Acceptance Scenarios**:

1. **Given** the user has valid data entered and taps Continue, **When** the save fails for any reason, **Then** the wizard remains on the current day's configuration step and displays a user-friendly error message.
2. **Given** the save of the day succeeded but saving an exercise block failed, **When** the error occurs, **Then** the wizard remains on the same step and the error message is shown (partial saves are surfaced as errors, not successes).
3. **Given** an error is displayed, **When** the user taps Continue again with the same data, **Then** the system retries the full save operation.
4. **Given** an error is displayed, **When** the user modifies their input, **Then** the error message is dismissed.

---

### User Story 3 - The exercise blocks are saved in full before advancing (Priority: P3)

The wizard must save both the training day and all its exercise blocks before navigating forward. The user should never be advanced to the next step with an incomplete or partially-saved day configuration.

**Why this priority**: Partial saves would create inconsistent data (a day with no exercises, or exercises linked to a day that wasn't saved). Data integrity must be guaranteed before any forward navigation.

**Independent Test**: Add multiple exercise blocks, tap Continue, intercept the saves, and verify that: (1) the day is saved first, (2) all exercise blocks are saved using the ID returned by the day save, (3) the wizard does not advance until all saves complete successfully.

**Acceptance Scenarios**:

1. **Given** the user has added three exercise blocks, **When** they tap Continue, **Then** all three exercise blocks are saved before the wizard advances.
2. **Given** the day is saved but saving the second of three exercise blocks fails, **When** the failure occurs, **Then** the wizard does not advance and an error is shown.

---

### Edge Cases

- What happens if the user leaves the day name blank and taps Continue? The Continue button must be disabled until the name is filled in.
- What happens if the user taps Continue multiple times rapidly? Only one save operation must run at a time; the button is disabled while saving is in progress.
- What happens if the network drops mid-save after the day is saved but before all blocks are saved? The save fails, the error is shown, and the user must retry the full operation; partial state on the server is handled on retry.
- What happens if the user navigates back from step 2 after a partial save? Navigating back is out of scope for this feature; that edge case is handled by the overall wizard navigation rules.
- What if the user adds no exercise blocks and taps Continue? The form is invalid; the Continue button must be disabled until at least one exercise block is added.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The second wizard step MUST display a form for each selected training day, allowing the user to enter a session name and one or more exercise blocks.
- **FR-002**: The session name field MUST be required; the Continue button MUST remain disabled until the session name is non-empty.
- **FR-003**: The user MUST be able to add one or more exercise blocks to the current day's form before proceeding.
- **FR-004**: At least one exercise block MUST be required; the Continue button MUST remain disabled if no exercise blocks have been added.
- **FR-005**: The Continue button MUST be disabled while a save operation is in progress to prevent duplicate submissions.
- **FR-006**: When the user taps Continue with valid data, the system MUST first save the training day to the user's workout plan using the plan identifier from the previous wizard step.
- **FR-007**: After the training day is saved successfully, the system MUST save each exercise block, linking them to the newly created training day using its identifier.
- **FR-008**: Each exercise block MUST be saved using the data provided by the user (exercise selection, target reps, weight, and rest period).
- **FR-009**: The wizard MUST NOT advance to the next step until the training day and all exercise blocks are fully saved.
- **FR-010**: If the save of the training day fails, the system MUST display a user-friendly error message and keep the user on the current step.
- **FR-011**: If the save of any exercise block fails, the system MUST display a user-friendly error message and keep the user on the current step.
- **FR-012**: After a save failure, all user-entered data MUST be preserved so the user can retry without re-entering.
- **FR-013**: When all saves succeed, the wizard MUST automatically advance to the next step without any additional user action.

### Key Entities

- **Training Day (WorkoutDayPlan)**: A named training session within a workout plan. Attributes: session name (required, user-provided), position within the plan (derived from the day's order in the selection sequence), active status (always true on creation). Linked to the parent workout plan by its identifier.
- **Exercise Block (ExerciseBlockPlan)**: A single exercise entry within a training day. Attributes: exercise selection, target repetitions, target weight, and rest period — all provided by the user. Linked to its parent training day by the training day's identifier.
- **Workout Plan (reference)**: The parent plan created or loaded in step 1 of the wizard. Its identifier is required to save a training day and must be available before step 2 begins.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of successful Continue taps (with valid data) result in all day and exercise data being saved and the wizard advancing.
- **SC-002**: 100% of failed save operations display a visible error message and keep the user on step 2 with all entered data intact.
- **SC-003**: The Continue button is disabled in 100% of cases where the session name is blank or no exercise blocks have been added.
- **SC-004**: No duplicate save requests are sent regardless of how many times the user taps Continue while a save is in progress.
- **SC-005**: A user with a stable connection can complete the step 2 form and save their configuration in under 60 seconds.

## Assumptions

- The workout plan identifier from step 1 is available and passed to step 2 before the user enters any data on this screen.
- The position/order index for each day is derived automatically from its position in the user's selection from step 1 (e.g., first selected day = index 0 or 1); the user does not enter this manually.
- All newly created training days are active by default; the user cannot set a day as inactive during wizard creation.
- The exercise block data structure includes at minimum: an exercise identifier, target repetitions, target weight, and rest period in seconds — matching what was configured in the exercise picker.
- If the training day was partially saved in a previous attempt (e.g., day saved but blocks failed), the retry submits the full operation again; the server is expected to handle this gracefully (idempotent or deduplicated on the server side).
- The scope of this feature is the save-on-continue behavior of step 2; loading or pre-filling existing data is out of scope.
- All saves use the authenticated network layer; token handling is managed by the existing infrastructure.
