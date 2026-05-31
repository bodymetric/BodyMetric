# Feature Specification: Home Screen Workout Data — Corrected API Contract

**Feature Branch**: `016-home-workout-api`  
**Created**: 2026-05-03  
**Status**: Draft  
**Input**: User description: "Fetch GET /api/home during splash. Populate workout card from currentWorkoutDayPlan (id, name, dayOfWeek, numberOfExercisesTotal, numberSetsTotal, timeEstimateToFinish). Populate exercises list from exercisesForToday (ordered by orderIndex, with sets ordered by orderIndex). Empty state when no plan. Error state with retry. 401 triggers token refresh and one retry."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - User sees their current day's workout plan on the home screen (Priority: P1)

When an authenticated user opens the app, the home screen loads their current workout plan from the server. The screen briefly shows skeleton placeholders, then reveals the workout card with the session name, day of the week, total exercises, total sets, and estimated duration — plus a "Start Workout" button. The exercise list below shows each exercise name with its target sets in order.

**Why this priority**: This is the primary home screen experience. Without live plan data the screen shows nothing meaningful.

**Independent Test**: Inject a mock response with `currentWorkoutDayPlan` and two `exercisesForToday` items each with sets. Verify the workout card shows all plan fields, and the exercises appear in `orderIndex` order with their sets listed.

**Acceptance Scenarios**:

1. **Given** the server returns a current workout day plan, **When** the home screen loads, **Then** the workout card displays the session name, day label, exercise count, set count, and estimated duration.
2. **Given** the server returns exercises for today, **When** the home screen loads, **Then** the exercises list shows each exercise in `orderIndex` order, with their target sets listed in `orderIndex` order.
3. **Given** the home data is loading, **When** the user sees the screen, **Then** skeleton placeholder components appear in place of the workout card and exercises list.
4. **Given** a populated workout card is shown, **When** the user sees it, **Then** a "Start Workout" button is present.

---

### User Story 2 - User with no plan for today sees a clear empty state (Priority: P2)

When the server response contains no current workout day plan (`currentWorkoutDayPlan` is null or absent), the home screen shows a card with "No workout plan registered for today" and a "New Workout Plan" button that opens the plan creation wizard. The exercises section is not shown.

**Why this priority**: New users or users without a plan for today need a clear, actionable path to create one.

**Independent Test**: Inject a mock response with `currentWorkoutDayPlan: null`. Verify the empty state message and "New Workout Plan" button appear; verify no exercises section is shown.

**Acceptance Scenarios**:

1. **Given** the server response has no current workout day plan, **When** the home screen loads, **Then** an empty state card shows "No workout plan registered for today" and a "New Workout Plan" button.
2. **Given** the empty state is shown, **When** the user taps "New Workout Plan", **Then** the plan creation wizard opens.
3. **Given** there is no current day plan, **When** the exercises section would normally appear, **Then** it is hidden entirely.

---

### User Story 3 - Session expiry is handled transparently (Priority: P3)

If the home data request fails because the session token has expired (401), the app attempts to refresh the token automatically and retries the request once. If the retry succeeds the home screen loads normally. If the retry also fails, the user is redirected to the login screen.

**Why this priority**: Token expiry is routine. Users should not be sent to login unnecessarily just because a token expired mid-session.

**Independent Test**: Simulate a 401 response followed by a successful refresh and a 200 on retry. Verify the home screen loads correctly. Then simulate a 401 that fails refresh. Verify the user reaches the login screen.

**Acceptance Scenarios**:

1. **Given** the home data request returns 401 and a token refresh succeeds, **When** the retry request returns 200, **Then** the home screen loads normally.
2. **Given** the home data request returns 401 and the token refresh also fails, **When** the failure is detected, **Then** the user is redirected to the login screen.

---

### User Story 4 - Network and server errors are shown with a retry option (Priority: P4)

If the home data request fails for any reason other than 401 (network timeout, server error, etc.), the skeleton is replaced with a friendly error message and a "Retry" button. Tapping retry re-fetches the data.

**Acceptance Scenarios**:

1. **Given** the home data request fails with a server error, **When** the failure is detected, **Then** a user-friendly error message replaces the skeleton and a "Retry" button appears.
2. **Given** an error message is shown, **When** the user taps "Retry", **Then** the home data request is re-attempted.

---

### Edge Cases

- What if `exercisesForToday` is present but empty? The exercises section is not shown — same as absent.
- What if an exercise has no sets? That exercise is still shown; the sets area is empty for that exercise.
- What if `orderIndex` values are not contiguous (e.g., 1, 3, 5)? Items are sorted by their `orderIndex` value regardless of gaps.
- What if the request takes longer than expected? The skeleton remains visible until the request completes or times out.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The home screen MUST initiate a data fetch when the app finishes its splash/loading phase.
- **FR-002**: While the data is loading, the workout card area and exercises area MUST show skeleton placeholder components.
- **FR-003**: If the response includes a current workout day plan, the workout card MUST display: session name, day of week, total exercise count, total set count, and estimated duration in minutes.
- **FR-004**: If the response includes a current workout day plan, the workout card MUST include a "Start Workout" action.
- **FR-005**: If the response includes today's exercises, the exercises section MUST display each exercise in ascending `orderIndex` order.
- **FR-006**: For each exercise shown, its target sets MUST be displayed in ascending `orderIndex` order.
- **FR-007**: If `currentWorkoutDayPlan` is null or absent, the home screen MUST show an empty state card with "No workout plan registered for today" and a "New Workout Plan" button.
- **FR-008**: The "New Workout Plan" button in the empty state MUST open the same plan creation wizard as the navigation menu item.
- **FR-009**: If `exercisesForToday` is null, absent, or empty, the exercises section MUST NOT be shown.
- **FR-010**: If the data request returns a session-expired response, the system MUST automatically attempt a token refresh and retry the data request exactly once.
- **FR-011**: If the token refresh and retry both fail, the system MUST redirect the user to the login screen.
- **FR-012**: If the data request fails for any other reason, the system MUST display a user-friendly error message and provide a way for the user to retry.

### Key Entities

- **Home Screen Data**: The server response containing the current workout day plan (optional) and today's exercises (optional).
- **Current Workout Day Plan**: The session scheduled for today. Attributes: identifier, session name, day of the week label, total exercise count, total set count, estimated duration in minutes.
- **Today's Exercise**: One exercise entry in today's list. Attributes: identifier, name, display order, and a list of target sets.
- **Target Set**: One set prescription within an exercise. Attributes: display order, target repetitions, target weight.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The home screen displays real data within 3 seconds under normal network conditions.
- **SC-002**: 100% of valid plan responses result in a populated workout card with all five data points (name, day, exercises, sets, duration).
- **SC-003**: 100% of session-expiry responses trigger exactly one token refresh and one retry before either succeeding or redirecting to login.
- **SC-004**: 100% of empty-plan responses show the empty state card and hide the exercises section.
- **SC-005**: Exercises and their sets appear in the correct `orderIndex` order in 100% of valid responses.

## Assumptions

- The 401 token refresh and retry mechanism is already implemented in the authenticated network layer; this feature does not change that logic.
- The plan creation wizard already exists and is accessible from the navigation menu; the "New Workout Plan" button reuses that same flow.
- The "Start Workout" button destination (the workout session flow) is handled by a separate feature; only its presence on the card is in scope here.
- The menu items "New Workout Plan" and "My Plans" adapt their enabled state based on plan presence — this behaviour is already specified and implemented in feature 015.
- `dayOfWeek` is a display label (e.g., "SUNDAY"); no calendar computation is required by the app.
- `timeEstimateToFinish` represents minutes as an integer.
