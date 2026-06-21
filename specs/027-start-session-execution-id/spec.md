# Feature Specification: Start Session Returns Exercise Block Execution ID

**Feature Branch**: `027-start-session-execution-id`  
**Created**: 2026-06-21  
**Status**: Draft  
**Input**: User description: "After executing POST /api/work-executions/start, the response MUST include the generated exerciseBlockExecutionId for each exercise block returned to the app."

## User Scenarios & Testing *(mandatory)*

### User Story 1 — App Receives and Stores Execution IDs When Starting a Session (Priority: P1)

When the user starts a workout session, the server response now includes a unique `exerciseBlockExecutionId` for every exercise block. The app reads this identifier for each block, stores it in memory alongside the block's display data (exercise name, sets, targets), and makes it available for subsequent actions within that session. The identifier is never shown to the user.

**Why this priority**: Without the execution ID, the "Log set" action cannot be completed — the identifier is the required key for recording a performed set against the correct exercise block. Receiving and storing it is the foundation of the entire logging flow.

**Independent Test**: Can be fully tested by starting a session and confirming that each exercise block in the active session screen has a non-zero execution ID stored in memory. Verification is via test assertions on the in-memory session model.

**Acceptance Scenarios**:

1. **Given** the server responds to session start with an `exerciseBlockExecutionId` for each exercise block, **When** the app receives the response, **Then** each exercise block in the in-memory session carries its corresponding `exerciseBlockExecutionId`.
2. **Given** the session has multiple exercise blocks, **When** the app processes the response, **Then** each block stores its own distinct `exerciseBlockExecutionId` — no shared or mixed-up identifiers between blocks.
3. **Given** the session starts successfully, **When** the user views the active session screen, **Then** all exercise blocks are displayed normally with no indication of the internal identifier to the user.

---

### User Story 2 — Logging a Set Uses the Correct Execution ID (Priority: P1)

When the user taps "Log set" for a specific exercise block, the app uses the `exerciseBlockExecutionId` stored for that exact block to submit the performed set to the server. The correct identifier is sent regardless of how many exercise blocks are on screen or which order the user chooses to log them in.

**Why this priority**: This is the direct payoff of User Story 1. A correct ID stored but not correctly used is equivalent to not having the ID at all. Both stories together deliver the complete "log a set" flow.

**Independent Test**: Can be verified by tapping "Log set" on any exercise block and confirming the submitted request uses the `exerciseBlockExecutionId` of that specific block, not another block's ID.

**Acceptance Scenarios**:

1. **Given** the session has started with valid execution IDs for all blocks, **When** the user taps "Log set" for the second exercise block, **Then** the request is submitted using the second block's `exerciseBlockExecutionId`, not the first block's.
2. **Given** the user logs sets on multiple exercise blocks in the same session, **When** each "Log set" tap completes, **Then** each request uses its own block's `exerciseBlockExecutionId` independently.
3. **Given** a valid execution ID is available, **When** "Log set" is tapped, **Then** the request succeeds and the set row is marked done — no "session data incomplete" error is shown.

---

### User Story 3 — Session Start Fails Gracefully If Execution ID Is Missing (Priority: P2)

If the server response omits the `exerciseBlockExecutionId` for one or more exercise blocks, the app must not silently proceed with a broken session. It shows a clear error message and does not enter the active session screen.

**Why this priority**: A session with missing execution IDs will reach a dead end when the user tries to log a set. Failing early at session start — with a clear message — is a better experience than a silent failure mid-workout.

**Independent Test**: Can be tested by simulating a server response that omits `exerciseBlockExecutionId` for at least one block. The app must display an error and not navigate to the active session screen.

**Acceptance Scenarios**:

1. **Given** the server responds without `exerciseBlockExecutionId` for any block, **When** the app attempts to start the session, **Then** the app shows an error message and remains on the check-in screen.
2. **Given** a session start error is shown, **When** the user dismisses it, **Then** all input (mood, warm-up checkboxes) is preserved so the user can retry without re-entering their choices.

---

### Edge Cases

- What happens when one block has a valid execution ID and another does not? The app must treat the entire session as invalid and refuse to enter the active session screen.
- What happens if the same `exerciseBlockExecutionId` appears for two different blocks? The app stores them as-is and passes them through unchanged — ID correctness is the server's responsibility.
- What happens when the session response has zero exercise blocks? The app behaves as before — no exercise blocks means no active session screen is shown (existing behaviour, unchanged).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The server response for session start MUST include an `exerciseBlockExecutionId` field for every exercise block in the response payload.
- **FR-002**: The app MUST read and store the `exerciseBlockExecutionId` for each exercise block as part of the in-memory session model when the session start response is received.
- **FR-003**: The `exerciseBlockExecutionId` MUST NOT be displayed to the user at any point.
- **FR-004**: When the user taps "Log set" for an exercise block, the app MUST use the `exerciseBlockExecutionId` stored for that specific block — not a default, fallback, or other block's ID.
- **FR-005**: The app MUST NOT allow "Log set" to complete with a placeholder or fallback execution ID (such as 0); if no valid ID is available, the action must be rejected with a visible error.
- **FR-006**: If the session start response is missing `exerciseBlockExecutionId` for any block, the app MUST treat the response as invalid, show an error message, and not navigate to the active session screen.
- **FR-007**: Each exercise block in the session MUST independently store its own `exerciseBlockExecutionId`; IDs MUST NOT be shared between blocks.

### Key Entities

- **ExerciseBlockExecution**: Server-side record created when a workout session starts. Has a unique `exerciseBlockExecutionId` that links performed sets back to the correct exercise block within the session.
- **ExerciseBlock (in-session)**: In-memory representation of one exercise in the active session. Carries `exerciseBlockExecutionId` as a required field for use when logging performed sets.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of "Log set" taps submit the correct `exerciseBlockExecutionId` for the tapped block — zero cross-block ID mixups.
- **SC-002**: Session start succeeds on the first attempt in 100% of cases where the server includes `exerciseBlockExecutionId` for all blocks.
- **SC-003**: When `exerciseBlockExecutionId` is missing from any block, 100% of cases show a user-visible error rather than silently entering a broken session.
- **SC-004**: No user-visible change to the active session screen layout or interaction flow — the execution ID is purely an internal detail.

## Assumptions

- The server will be updated independently to include `exerciseBlockExecutionId` in the session start response; the app change and server change are coordinated but deployed separately.
- The `exerciseBlockExecutionId` is always a positive integer when present; the value 0 is treated as absent/invalid.
- Authentication tokens continue to be attached to all outgoing requests by the existing network layer; no auth changes are needed.
- The active session screen UI, exercise block order, and set logging UI remain unchanged by this feature.
- The app currently has defensive handling for missing `exerciseBlockExecutionId` from a prior bug-fix iteration; this feature supersedes that defensive code by making the field required at the decode boundary.
