# Feature Specification: Log Set Performed

**Feature Branch**: `026-log-set-performed`  
**Created**: 2026-06-11  
**Status**: Draft  
**Input**: User description: "Implement the 'Log set' behavior on the ExerciseBlockExecution list screen."

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Log a Performed Set (Priority: P1)

During an active workout session, the user sees a list of exercise block executions. Each row shows target weight and reps. The user enters actual weight and reps on a row, then presses "Log set" to record performance for that specific exercise block execution. The server receives the correct ID, weight, and reps.

**Why this priority**: This is the core workout-tracking action. Without it, the active session screen cannot capture any data, making the entire workout execution feature incomplete.

**Independent Test**: Can be fully tested by opening the active session screen with at least one exercise block execution row, entering weight and reps, tapping "Log set," and confirming the server receives the correct `exerciseBlockExecutionId`, `weight`, and `reps`.

**Acceptance Scenarios**:

1. **Given** the active session screen displays one or more exercise block execution rows, **When** the user enters a weight and reps for a row and taps "Log set," **Then** the app sends a request to record the performed set for that exact row's exercise block execution ID, including the entered weight and reps, and the row is visually marked as logged.
2. **Given** the user taps "Log set" and the request succeeds, **When** the response is received, **Then** the set row shows a confirmed/done state and the user can proceed to the next set or exercise.
3. **Given** the user has entered values for one exercise block execution row, **When** they tap "Log set" on a different row, **Then** only the ID of that second row is sent in the request — the first row is unaffected.

---

### User Story 2 — Error Handling for Log Set (Priority: P2)

If the network request to log a set fails (network error or server error), the user is clearly informed and can retry without losing the values they entered.

**Why this priority**: Without error handling, a failed log silently discards workout data, leading to incomplete records and user frustration.

**Independent Test**: Can be tested by simulating a server or network error and confirming the user sees an error message and the "Log set" button is re-enabled with the original values still present.

**Acceptance Scenarios**:

1. **Given** the user taps "Log set," **When** the server returns an error (4xx or 5xx), **Then** the app shows a user-friendly error message and the "Log set" button is re-enabled.
2. **Given** the user taps "Log set," **When** there is no network connectivity, **Then** the app shows a connectivity error message and the button is re-enabled.
3. **Given** a log request fails, **When** the user corrects the issue and taps "Log set" again, **Then** the app retries and succeeds normally.

---

### Edge Cases

- What happens when the user taps "Log set" twice rapidly (double-tap)? The button must be disabled while the request is in flight to prevent duplicate submissions.
- What happens if `weight` is 0? The app must allow 0 as a valid entry (bodyweight exercises).
- What happens if `reps` is 0? The app must prevent submission and show a validation message.
- What if the exercise block execution ID is unavailable at logging time? The app must not send the request and must surface an error.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When the user taps "Log set" for a specific exercise block execution row, the app MUST send a request to record the performed set for that exact exercise block execution, identified by its unique ID.
- **FR-002**: The request MUST include the weight value entered by the user for that row.
- **FR-003**: The request MUST include the reps value entered by the user for that row.
- **FR-004**: While the log request is in flight, the "Log set" button for that row MUST be disabled to prevent duplicate submissions.
- **FR-005**: Upon a successful response, the exercise block execution row MUST be visually updated to reflect its logged/completed state.
- **FR-006**: Upon a failed request, the app MUST display a user-friendly error message and re-enable the "Log set" button so the user can retry.
- **FR-007**: The app MUST NOT allow submission when `reps` is 0; it must show a validation message instead.
- **FR-008**: The app MUST allow `weight` of 0 (valid for bodyweight exercises).
- **FR-009**: Each exercise block execution row MUST maintain its own independent input state so that logging one row does not affect another row's inputs.

### Key Entities

- **ExerciseBlockExecution**: Represents one exercise block within an active workout session. Has a unique `exerciseBlockExecutionId`. Displays target weight/reps and accepts actual weight/reps input from the user.
- **PerformedSet**: The record of one completed set. Contains `weight` (numeric, supports decimals) and `reps` (whole number ≥ 1) as provided by the user.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The user can log a set in under 10 seconds from the moment they open the log sheet to receiving visual confirmation.
- **SC-002**: 100% of "Log set" taps send the correct `exerciseBlockExecutionId` for the tapped row — no cross-row ID mixup occurs.
- **SC-003**: Duplicate submissions are prevented in 100% of cases — a second tap while a request is in flight produces no additional server call.
- **SC-004**: On network or server failure, 100% of error cases surface a visible message and restore the "Log set" button within 2 seconds of the failure.

## Assumptions

- The active session screen already displays the list of exercise block executions with their IDs available from the data loaded when the workout session was started.
- The existing weight and reps input UI (log sheet with "Log set" button) will be wired to the new server call; no new input components need to be created.
- Authentication tokens are attached to all outgoing requests by the existing network layer; no auth changes are needed.
- The server returns 200 or 201 on success; any other HTTP status is treated as an error.
- `exerciseBlockExecutionId` refers to the execution-level identifier (not the plan-level ID) that the server associates with each exercise block within the started workout session.
