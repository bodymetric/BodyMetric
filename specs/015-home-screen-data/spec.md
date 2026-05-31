# Feature Specification: Home Screen Live Data

**Feature Branch**: `015-home-screen-data`  
**Created**: 2026-05-03  
**Status**: Draft  
**Input**: User description: "Load home screen data from server on app open. Show skeleton while loading. Workout card shows current plan (name, exercises, sets, time) or empty state with 'New Workout Plan' button. Menu enables/disables items based on plan presence. Exercises card shows today's exercises if available."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - User sees their current workout plan on the home screen (Priority: P1)

A signed-in user who has already set up a workout plan opens the app. The home screen briefly shows skeleton placeholders while data loads, then reveals their current training day — the session name, number of exercises, total sets, and estimated duration — along with a "Start Workout" button. The menu's "New Workout Plan" item is disabled and "My Plans" is enabled.

**Why this priority**: This is the primary value of the home screen. Without live plan data, users see stale or incorrect information and cannot quickly start their workout.

**Independent Test**: Authenticate with an account that has an active plan. Open the app. Verify: (1) skeleton shown briefly, (2) workout card shows the plan name, exercise count, set count, and duration, (3) "Start Workout" button is present, (4) menu has "New Workout Plan" disabled and "My Plans" enabled.

**Acceptance Scenarios**:

1. **Given** the user has an active workout plan, **When** the home screen loads, **Then** the workout card shows the session name, number of exercises, total sets, and estimated duration.
2. **Given** the home screen data is loading, **When** the user sees the screen, **Then** skeleton placeholder components are shown instead of empty or stale content.
3. **Given** the user has an active workout plan, **When** they open the dropdown menu, **Then** "New Workout Plan" is disabled and "My Plans" is enabled.
4. **Given** the workout card is populated, **When** the user sees it, **Then** a "Start Workout" button is visible and tappable.

---

### User Story 2 - User with no plan sees a clear empty state on the home screen (Priority: P2)

A signed-in user who has not yet created a workout plan opens the app. The home screen shows a card indicating that no plan is registered, along with a "New Workout Plan" button that opens the same wizard available from the menu. The menu's "New Workout Plan" item is enabled and "My Plans" is disabled.

**Why this priority**: New users and users who have deleted their plan need a clear path to create one. Without this, they see an empty screen with no guidance.

**Independent Test**: Authenticate with an account that has no active plan. Open the app. Verify: (1) workout card shows "No workout plan registered" message, (2) "New Workout Plan" button is present and navigates to the plan wizard, (3) menu has "New Workout Plan" enabled and "My Plans" disabled.

**Acceptance Scenarios**:

1. **Given** the user has no active workout plan, **When** the home screen loads, **Then** the workout card shows a message that no plan is registered and a "New Workout Plan" button.
2. **Given** the empty state is shown, **When** the user taps "New Workout Plan", **Then** the same plan creation wizard opens as when using the menu item.
3. **Given** the user has no active plan, **When** they open the dropdown menu, **Then** "New Workout Plan" is enabled and "My Plans" is disabled.

---

### User Story 3 - User sees today's exercises listed on the home screen (Priority: P3)

A user whose plan includes exercises scheduled for today sees a card on the home screen listing those exercises. If no exercises are scheduled for today (or the data is unavailable), the exercises card is simply not shown — no error, no empty card.

**Why this priority**: Today's exercise list gives the user a preview of their session without opening the full workout. Absence is handled gracefully with no visible impact on other cards.

**Independent Test**: With an account that has exercises scheduled today, open the home screen and verify an exercises card appears with the exercise names. With an account that has no exercises today, verify no exercises card appears.

**Acceptance Scenarios**:

1. **Given** today's data includes exercises, **When** the home screen loads, **Then** an exercises card is shown with the exercises listed.
2. **Given** today's data has no exercises, **When** the home screen loads, **Then** no exercises card is shown at all.
3. **Given** the exercises data is missing from the server response, **When** the home screen loads, **Then** no exercises card is shown.

---

### Edge Cases

- What happens if the data load fails (network error, server error)? The skeleton should be replaced with a non-blocking error state; the user can still navigate to other parts of the app.
- What happens if the data takes a long time to load? The skeleton remains visible until the data arrives or the request times out.
- What happens if the user navigates away while loading and returns? The screen should show a fresh loading state or cached data, not a stuck skeleton.
- What if `currentWorkoutDayPlan` is present but some fields are missing (e.g., no `timeEstimateToFinishes`)? Missing optional fields should be hidden gracefully; the card should still render with available data.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When the authenticated user opens the app, the home screen MUST load its data from the server before presenting any content.
- **FR-002**: While the home screen data is loading, the screen MUST display skeleton placeholder components in place of the actual content.
- **FR-003**: If the server response includes an active workout day plan, the home screen MUST display a workout card showing the plan's session name, total number of exercises, total number of sets, and estimated duration.
- **FR-004**: If the server response includes an active workout day plan, the workout card MUST show a "Start Workout" action.
- **FR-005**: If the server response does not include an active workout day plan (absent or empty), the home screen MUST display a workout card with a message indicating no plan is registered.
- **FR-006**: The "No plan" workout card MUST include a "New Workout Plan" action that opens the same plan creation wizard accessible from the navigation menu.
- **FR-007**: If the server response includes an active workout day plan, the navigation menu item "New Workout Plan" MUST be disabled and "My Plans" MUST be enabled.
- **FR-008**: If the server response does not include an active workout day plan, the navigation menu item "New Workout Plan" MUST be enabled and "My Plans" MUST be disabled.
- **FR-009**: If the server response includes a non-empty exercises list for today, the home screen MUST display an exercises card populated with those exercises.
- **FR-010**: If the server response does not include exercises for today (absent, empty, or null), the exercises card MUST NOT be shown on the home screen.
- **FR-011**: If the data load fails, the screen MUST exit the skeleton state and present a recoverable error state rather than remaining stuck on skeletons.

### Key Entities

- **Home Data**: The complete server response for the home screen. Contains the current workout day plan (optional) and today's exercise list (optional).
- **Current Workout Day Plan**: The training session scheduled for the current day. Attributes: session name, total exercises count, total sets count, estimated duration in minutes.
- **Exercise Entry**: A single exercise in today's list. Attributes: at minimum a display name; additional detail fields as provided by the server.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The home screen displays real data within 3 seconds of the user reaching it under normal network conditions.
- **SC-002**: 100% of users with an active plan see the workout card populated with their plan data on first home screen load.
- **SC-003**: 100% of users without a plan see the empty state card with the "New Workout Plan" button.
- **SC-004**: The skeleton loading state is visible for no longer than 5 seconds before being replaced by data or an error state.
- **SC-005**: Tapping "New Workout Plan" from the empty state card opens the plan wizard in 100% of cases, producing the same result as tapping the menu item.

## Assumptions

- The server endpoint for home screen data is called once when the home screen becomes active (i.e., after authentication and splash resolution).
- If both `currentWorkoutDayPlan` and `exercisesForToday` are absent from the response, the home screen shows only the empty workout card (no exercises card, no other cards).
- The "Start Workout" button's destination (the active workout session flow) is handled by an existing or future feature; this spec only requires the button to be present when a plan exists.
- The `timeEstimateToFinishes` value represents minutes.
- Exercise entries in `exercisesForToday` contain at minimum a display name; the exercises card renders all exercises returned by the server.
- Menu item state (enabled/disabled) is determined solely by the presence of `currentWorkoutDayPlan`; no other conditions apply within this feature scope.
