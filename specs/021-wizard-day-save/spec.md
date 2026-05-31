# Feature Specification: Wizard Step 2 — Save Day Config on Continue

**Feature Branch**: `021-wizard-day-save`
**Created**: 2026-05-31
**Status**: Draft
**Input**: User description — save workout day configuration to the server when the user presses Continue on wizard step 2

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Save Workout Day on Continue (Priority: P1)

When a user has configured a workout day on step 2 (set a session name, chosen exercises, and configured per-set reps, weights, and rest time), tapping Continue saves the full configuration to the server before the wizard advances. The user sees the Continue button become temporarily unavailable during the save, then the wizard moves to the next step once saving completes.

**Why this priority**: Without this save, no workout day data persists. This is the core requirement of the feature — everything else is supporting behaviour.

**Independent Test**: Configure one exercise block on step 2 and tap Continue. Verify the server receives the correct workout day name, exercise block, and per-set data. Verify the wizard advances to step 3.

**Acceptance Scenarios**:

1. **Given** the user has filled in a session name and at least one valid exercise block on step 2, **When** the user taps Continue, **Then** the app sends the day configuration to the server before advancing.
2. **Given** the save request is in flight, **When** the Continue button is visible, **Then** it is disabled and gives visual feedback that a save is in progress.
3. **Given** the server accepts the save request, **When** the response is successful, **Then** the wizard navigates to the next step automatically.
4. **Given** the request payload, **When** it is sent, **Then** it includes the session name, day order index, `isActive: true`, all exercise blocks with their exercise IDs, rest times, and all configured sets with their individual rep counts and weights.
5. **Given** the workout plan ID from the previous step, **When** the request is sent, **Then** it targets the correct plan-specific endpoint using that ID.

---

### User Story 2 — Error Handling on Save Failure (Priority: P2)

When the server returns an error (network failure, server error, or validation error), the wizard stays on step 2 and shows the user a clear, actionable error message so they can retry.

**Why this priority**: Silently failing or crashing would corrupt the user's plan-building flow. Clear error recovery is required before this feature can ship.

**Independent Test**: Simulate a server failure on Continue. Verify the wizard stays on step 2, an error message is displayed, and the user can attempt to save again.

**Acceptance Scenarios**:

1. **Given** the server returns an error on the save request, **When** the response is received, **Then** the wizard stays on step 2 and displays a user-readable error message.
2. **Given** an error message is shown, **When** the user corrects the issue or simply taps Continue again, **Then** a new save attempt is made and the error message clears.
3. **Given** a network failure, **When** the error message is displayed, **Then** it does not expose technical details; it uses plain language (e.g., "Could not save your workout day. Please try again.").

---

### Edge Cases

- What if the user taps Continue with no exercise blocks? The Continue button must be disabled until at least one valid exercise block exists — this is already enforced by the existing validation gate.
- What if the session name is empty? The Continue button must be disabled — already enforced by existing validation.
- What if the workout plan ID from the previous step is missing (e.g., plan creation failed silently)? The save must not be attempted; the user must not reach step 2 without a valid plan ID.
- What if the user taps Continue multiple times in rapid succession? Only one save request must be in flight at a time — duplicate taps are ignored while a request is running.
- What if the device loses internet mid-request? A network error is returned and the error handling flow applies.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When the user taps Continue on step 2, the app MUST send a save request to the server containing the full workout day configuration before navigating forward.
- **FR-002**: The save request MUST include: the session name, the day's order index within the wizard, `isActive` set to true, and all exercise blocks.
- **FR-003**: Each exercise block in the request MUST include: the exercise identifier, the block's order index, the rest duration in seconds, the optional flag (always false by default), and all configured sets.
- **FR-004**: Each set in the request MUST include: the set's order index, the target rep count, and the target weight.
- **FR-005**: The save request MUST be targeted at the workout plan created or loaded in the previous wizard step, using that plan's server-assigned identifier.
- **FR-006**: The Continue button MUST be visually disabled and non-interactive for the entire duration of the save request.
- **FR-007**: Only one save request MUST be allowed in flight at a time; duplicate Continue taps while saving MUST be ignored.
- **FR-008**: If the save request succeeds, the wizard MUST advance to the next step.
- **FR-009**: If the save request fails for any reason, the wizard MUST remain on step 2 and display a user-readable error message.
- **FR-010**: The error message MUST be dismissed or replaced when the user initiates a new save attempt.
- **FR-011**: All save requests MUST be sent using the authenticated user's session credentials.

### Key Entities

- **WorkoutDayConfig**: The full configuration for one training day — includes session name, day position in the week, and an ordered list of exercise blocks.
- **ExerciseBlock**: One exercise slot within a day — includes exercise identity, position in the workout, rest time, and an ordered list of target sets.
- **TargetSet**: One individual set within an exercise block — includes its position, target rep count, and target weight.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can configure and save a workout day with up to 6 exercise blocks and 5 sets each in under 5 seconds of server response time.
- **SC-002**: 100% of save requests carry the complete payload (name, orderIndex, isActive, all exercise blocks, all sets) — verified by service-layer unit tests.
- **SC-003**: The Continue button is disabled for the full duration of every save request — verified by UI state tests.
- **SC-004**: A save failure never causes the wizard to advance — verified by unit tests covering the error path.
- **SC-005**: All existing wizard unit tests continue to pass after this feature is added.

## Assumptions

- The workout plan ID needed for the endpoint URL is stored in the view model from step 1 and is available when step 2's Continue is tapped.
- `isOptional` on each exercise block defaults to `false`; no UI toggle for optional blocks is in scope for this feature.
- The session name used in the request is the workout day name already displayed on the screen (e.g., "Peito e Tríceps") — the user has already set this before tapping Continue.
- The order index of each exercise block in the request is its 1-based position in the current block list on screen.
- The order index of each target set is its 1-based position in the set table on screen.
- A successful server response means any 2xx HTTP status code; non-2xx is treated as a failure.
- The error message copy is "Could not save your workout day. Please try again." — consistent with existing wizard error messages in the codebase.
- The user's authentication token is already managed by the existing `NetworkClient` bearer token injection and does not require changes for this feature.
