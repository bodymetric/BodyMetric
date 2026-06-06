# Feature Specification: Home Refresh After Workout Completion

**Feature Branch**: `022-home-refresh-post-workout`
**Created**: 2026-05-31
**Status**: Draft
**Input**: User description — after ending a workout session the app must call `GET /api/home?currentDayOfWeek=<WEEKDAY>` and update the home screen

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Home Screen Refreshes After Completing a Workout (Priority: P1)

After finishing all sets and tapping "Done" on the completion screen, the app automatically dismisses the session flow and refreshes the home screen with the latest data from the server.

**Why this priority**: Without this refresh the home screen shows stale data (e.g., the completed workout still shown as pending). The user expects the UI to reflect their current training state as soon as they return to the home screen.

**Independent Test**: Mock a workout-complete event, verify that `TodayViewModel.loadState` transitions through `.loading` → `.loaded` after `showCheckIn` becomes false.

**Acceptance Scenarios**:

1. **Given** a completed workout (all sets logged), **When** the user taps "Done" on `WorkoutCompleteView`, **Then** the entire CheckIn flow is dismissed and the user is returned to the home screen
2. **Given** the home API call succeeds, **When** the reload finishes, **Then** `TodayViewModel.loadState` is `.loaded(freshData)` with the latest server response
3. **Given** the home API call fails, **When** the reload errors, **Then** `TodayViewModel.loadState` is `.failed(message)` and the error banner with a retry button is visible

---

### User Story 2 — Home API Request Includes Current Day (Priority: P2)

Every call to `GET /api/home` must include a `currentDayOfWeek` query parameter matching the device's current calendar day, so the server returns the correct workout for today.

**Why this priority**: Without the query parameter the server cannot determine which day's workout to return. This is a prerequisite for the home screen to be accurate after a workout.

**Independent Test**: Assert that the URL constructed by `HomeService.fetchHomeData()` contains `?currentDayOfWeek=<UPPERCASED_WEEKDAY>`.

**Acceptance Scenarios**:

1. **Given** today is Monday, **When** `fetchHomeData()` is called, **Then** the request URL is `https://api.bodymetric.com.br/api/home?currentDayOfWeek=MONDAY`
2. **Given** today is Sunday, **When** `fetchHomeData()` is called, **Then** the request URL ends with `currentDayOfWeek=SUNDAY`

---

### Edge Cases

- What happens if the user manually dismisses `CheckInView` (back button, before starting)? The home screen still reloads — a harmless extra refresh keeps data fresh.
- What if the user taps "Done" rapidly twice? `TodayViewModel.loadHomeData` already guards against re-entry while loading (`guard loadState != .loading`), so only one request fires.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When the user taps "Done" on `WorkoutCompleteView`, the entire `CheckInView` fullScreenCover MUST be dismissed and the user returned to `TodayView`
- **FR-002**: After `CheckInView` is dismissed, the home screen MUST call `GET /api/home?currentDayOfWeek=<WEEKDAY>` to refresh its data
- **FR-003**: The `currentDayOfWeek` query parameter MUST be derived from the device's current calendar day at request time, uppercased (e.g., "MONDAY")
- **FR-004**: While the refresh is in progress, the home screen MUST show the loading/skeleton state
- **FR-005**: If the refresh fails, the home screen MUST show the error state with a retry button (existing error UI reused)
- **FR-006**: The request MUST include the `Authorization: Bearer <token>` header (handled automatically by `NetworkClient`)

### Key Entities

- **HomeScreenData**: The decoded server response refreshed after workout completion
- **TodayViewModel.loadState**: The state machine driving the home UI (`idle → loading → loaded/failed`)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Tapping "Done" returns the user to the home screen in ≤ 300 ms (excluding network round-trip)
- **SC-002**: The home screen reflects updated server data within one network round-trip after workout completion
- **SC-003**: 100% of `GET /api/home` calls include the `currentDayOfWeek` query parameter matching the device's current weekday

## Assumptions

- The `GET /api/home?currentDayOfWeek=<WEEKDAY>` endpoint is the same API already used for the initial home load; no new endpoint is needed
- Bearer token injection is handled automatically by `NetworkClient` (feature 010); no new auth code required
- Refreshing the home when `CheckInView` is dismissed for any reason (not only post-workout) is acceptable; extra refreshes are harmless
