# Feature Specification: Start Workout Execution

**Feature Branch**: `025-start-workout-execution`
**Created**: 2026-05-31
**Status**: Draft
**Input**: Adapt the Start Workout flow — Begin Session calls the execution API and navigates to the active workout screen.

## User Scenarios & Testing

### User Story 1 — Begin Session Starts the Workout (Priority: P1)

The user is on the check-in screen ("Ready to lift?"). They select a mood and tap "Begin Session". The app submits the plan ID, week number, and selected mood to the server. If the call succeeds, the user is taken to the active workout screen which shows all exercise blocks and target sets for the session.

**Why this priority**: This is the core entry point to every workout. Without it the user cannot start exercising.

**Independent Test**: Present the check-in screen with a valid plan; select a mood; tap "Begin Session"; verify the active workout screen appears with the correct exercise data from the server response.

**Acceptance Scenarios**:

1. **Given** the check-in screen is displayed with a valid workout plan and the user has selected a mood, **When** the user taps "Begin Session", **Then** the app sends the plan ID, week number (`1`), and the selected mood in uppercase to the server.
2. **Given** the server responds successfully, **When** the response is received, **Then** the app navigates to the active workout screen.
3. **Given** the active workout screen is displayed, **When** the user views it, **Then** it shows the workout plan name and the total number of sets.
4. **Given** the active workout screen is displayed, **When** the user views the exercise list, **Then** exercise blocks appear sorted by their order index.
5. **Given** an exercise block is displayed, **When** the user views it, **Then** it shows the exercise name, number of sets, rest time in seconds, and its target sets sorted by order index.
6. **Given** a target set is displayed, **When** the user views it, **Then** it shows the target reps and target weight.

---

### User Story 2 — Loading and Error States (Priority: P2)

While the server call is running, the "Begin Session" button is disabled and shows a loading indicator. If the call fails, the user stays on the check-in screen and sees an error message. They can retry without reloading the screen.

**Why this priority**: Without this, the user can tap the button multiple times and has no feedback when something goes wrong.

**Independent Test**: Simulate a server failure after tapping "Begin Session"; verify the user stays on the check-in screen with an error message, and the button becomes tappable again.

**Acceptance Scenarios**:

1. **Given** the user taps "Begin Session", **When** the request is in flight, **Then** the button is disabled and shows a loading indicator.
2. **Given** the request fails, **When** the error is received, **Then** the user stays on the check-in screen and an error message is shown.
3. **Given** an error message is shown, **When** the user selects a mood and taps "Begin Session" again, **Then** a new request is sent and the error clears.

---

### Edge Cases

- The user taps "Begin Session" without selecting a mood: the button remains disabled.
- The server returns a workout plan with no exercise blocks: the active workout screen shows the plan name with zero total sets and an empty list.
- Mood values sent to the server are always uppercase (`LOW`, `OK`, `HIGH`).
- The `workExecutionId` from the server response must be retained in memory for future use during the session.

## Requirements

### Functional Requirements

- **FR-001**: When the user taps "Begin Session", the app MUST send the workout plan ID, week number `1`, and the selected mood (uppercase) to the server.
- **FR-002**: The "Begin Session" button MUST be disabled and show a loading indicator while the request is in progress.
- **FR-003**: If the request succeeds, the app MUST navigate to the active workout screen without performing the navigation unless the request succeeds.
- **FR-004**: If the request fails, the app MUST stay on the check-in screen and display an error message; the button MUST become active again.
- **FR-005**: The active workout screen MUST display the workout plan name and total number of sets from the server response.
- **FR-006**: The active workout screen MUST display the list of exercise blocks sorted ascending by `orderIndex`.
- **FR-007**: Each exercise block MUST display: exercise name, number of sets, rest time in seconds, and its target sets sorted ascending by `orderIndex`.
- **FR-008**: Each target set MUST display: target reps and target weight.
- **FR-009**: The `workExecutionId` from the server response MUST be retained in the active workout screen for use in subsequent requests.

### Key Entities

- **WorkExecution**: A started workout session. Attributes: `workExecutionId`, `workoutPlanId`, `workoutPlanName`, `totalNumberOfSets`, ordered list of `ExerciseBlockPlan`.
- **ExerciseBlockPlan**: One exercise in the session. Attributes: `exerciseBlockPlanId`, `exerciseId`, `exerciseName`, `orderIndex`, `restSeconds`, `isOptional`, `numberOfSets`, ordered list of `TargetSet`.
- **TargetSet**: One planned set within a block. Attributes: `targetSetId`, `orderIndex`, `targetReps`, `targetWeight`.
- **StartSessionRequest**: The payload to start a session. Attributes: `planId`, `actualWeekNumber` (always `1`), `feeling` (uppercase mood).

## Success Criteria

### Measurable Outcomes

- **SC-001**: The user can start a workout session with a single tap (after selecting mood) and reach the active screen in under 5 seconds on a normal connection.
- **SC-002**: 100% of successful session-start responses result in navigation to the active workout screen with complete exercise data.
- **SC-003**: 100% of failed session-start responses keep the user on the check-in screen with a visible error message and a re-enabled button.
- **SC-004**: The active workout screen correctly reflects all exercise blocks and target sets from the server response with no data loss or reordering errors.

## Assumptions

- `actualWeekNumber` is hardcoded to `1` for this iteration; dynamic week tracking is out of scope.
- The mood values sent to the server match the uppercase labels: `LOW`, `OK`, `HIGH`.
- The check-in screen already receives the plan ID from the home screen; this is not changing.
- The `workExecutionId` is held in memory for the duration of the active session screen; no local persistence is needed at this stage.
- The existing warm-up checklist on the check-in screen is not affected by this change.
