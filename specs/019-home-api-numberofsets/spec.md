# Feature Specification: Home API — Replace targetSets with numberOfSets

**Feature Branch**: `019-home-api-numberofsets`  
**Created**: 2026-05-24  
**Status**: Draft  
**Input**: User description: "Update the GET /api/home response contract to replace targetSets array with scalar numberOfSets field in exercisesForToday"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Home Screen Shows Set Count Without Loading Set Details (Priority: P1)

When a user opens the app's home screen, the app fetches today's workout summary. Each exercise in today's plan displays the number of sets (e.g., "3 sets") as a simple numeric value. The system no longer fetches or sends the full list of individual set configurations — only the total count is needed for display.

**Why this priority**: This is the core contract change. Every downstream UI and data layer depends on this shape. Delivering this first enables all other stories to build on a stable foundation.

**Independent Test**: Load the home screen for a user who has a current workout plan. Verify that each exercise row displays its set count as a number and that no set-detail data is loaded or shown.

**Acceptance Scenarios**:

1. **Given** a user has a current workout plan with today configured, **When** the home screen loads, **Then** each exercise in "exercises for today" shows a `numberOfSets` integer and no individual set breakdown.
2. **Given** the server returns `numberOfSets: 3` for an exercise, **When** the home screen renders, **Then** the exercise row displays "3 sets" (or equivalent).
3. **Given** the server omits `targetSets` from the response entirely, **When** the app parses the response, **Then** no decoding error occurs and the screen renders correctly.

---

### User Story 2 — All Data Consumers Updated to Use numberOfSets (Priority: P2)

All layers of the app that previously read or wrote `targetSets` for the home screen exercise list are updated to use the scalar `numberOfSets` field. This includes data transfer objects, model mappers, UI components, and test fixtures.

**Why this priority**: Without this cleanup, stale `targetSets` references will cause compile errors, decoding failures, or incorrect data being shown to users.

**Independent Test**: After updating all consumers, build the app and run the full test suite. Zero compilation errors and zero test failures related to `targetSets` must remain.

**Acceptance Scenarios**:

1. **Given** the updated response contract, **When** the app model layer decodes the home screen response, **Then** each exercise is decoded using `numberOfSets` (Int) with no reference to `targetSets`.
2. **Given** any unit test or mock fixture that previously used `targetSets`, **When** the tests run, **Then** all pass using the new `numberOfSets` field.
3. **Given** the home screen UI components that previously iterated over `targetSets`, **When** the screen renders, **Then** they display the set count from `numberOfSets` without errors.

---

### User Story 3 — Summary Totals Reflect numberSetsTotal (Priority: P3)

The workout day plan summary returned alongside `exercisesForToday` includes a `numberSetsTotal` field representing the sum of all sets across all exercises for the day. The home screen uses this total to show an overall set count (e.g., "12 sets total") in the workout card.

**Why this priority**: This aggregated total is a display enhancement. The screen is usable without it (individual set counts are shown per exercise), so it is lower priority than the core contract change.

**Independent Test**: Load the home screen for a user with a 4-exercise plan where total sets = 12. Verify the workout card summary shows "12 sets" (or equivalent total), sourced from `numberSetsTotal`.

**Acceptance Scenarios**:

1. **Given** `currentWorkoutDayPlan.numberSetsTotal` is 12, **When** the home workout card renders, **Then** the total set count displayed equals 12.
2. **Given** the previous home model did not include `numberSetsTotal`, **When** the updated model is decoded, **Then** the field is present and correctly bound in the UI.

---

### Edge Cases

- What happens when `numberOfSets` is 0 for an exercise? The app must display a sensible fallback (e.g., "0 sets") without crashing.
- What happens when `numberSetsTotal` is 0? The workout card should display "0 sets" or omit the total gracefully.
- What happens if `exercisesForToday` is an empty array? The home screen must not crash and should show an appropriate empty state.
- What happens when `orderIndex` values are non-contiguous (e.g., 1, 3, 5)? Exercises must still render in ascending `orderIndex` order.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The home screen data contract MUST include `numberOfSets: Int` on each exercise item in `exercisesForToday`, replacing the previous `targetSets` array.
- **FR-002**: The home screen data contract MUST include `numberSetsTotal: Int` on `currentWorkoutDayPlan`, representing the total set count for the day.
- **FR-003**: The `targetSets` field and its associated type (`TodayExerciseSet`) MUST be completely removed from all app data models, mappers, and UI components that consumed the home screen exercise list.
- **FR-004**: Exercise ordering MUST continue to use `orderIndex` for rendering exercises in the correct sequence.
- **FR-005**: All unit tests and mock fixtures that referenced `targetSets` for the home exercise list MUST be updated to use `numberOfSets`.
- **FR-006**: The app MUST NOT crash or produce a decoding error when the server response contains no `targetSets` field.
- **FR-007**: The home screen exercise list MUST display each exercise's set count using the `numberOfSets` value from the server.
- **FR-008**: The workout day plan summary card on the home screen MUST display the total set count sourced from `numberSetsTotal`.

### Key Entities

- **WorkoutDayPlanSummary**: Today's workout plan header shown in the home card. Fields: `id`, `name`, `dayOfWeek`, `numberOfExercisesTotal`, `numberSetsTotal`, `timeEstimateToFinish`.
- **TodayExercise**: A single exercise entry shown in the home screen exercise list. Fields: `id`, `name`, `orderIndex`, `numberOfSets` (replaces the old `sets: [TodayExerciseSet]`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The home screen loads and displays today's exercises with set counts in under 2 seconds on a standard mobile connection.
- **SC-002**: 100% of existing home screen tests pass after the migration from `targetSets` to `numberOfSets` with zero skipped or deleted tests (only updates allowed).
- **SC-003**: The app builds with zero errors and zero warnings related to `targetSets` after all consumer updates are applied.
- **SC-004**: The home screen correctly displays the total set count for any day plan with 1–30 exercises and 1–10 sets each.

## Assumptions

- The server-side API change (removing `targetSets`, adding `numberOfSets` and `numberSetsTotal`) is already implemented or will be delivered in parallel; this feature covers the iOS client side only.
- `numberOfSets` is always a non-negative integer; the client does not need to handle fractional or null values.
- `numberSetsTotal` is always a non-negative integer equal to the sum of all `numberOfSets` values for the day's exercises.
- The `TodayExercise` model previously stored `sets: [TodayExerciseSet]` (introduced in feature 016); this array and `TodayExerciseSet` are removed and replaced by the scalar `numberOfSets: Int`.
- No other screens (workout execution, plan wizard, check-in) are affected by this change — only the home screen data pipeline.
- Existing `WorkoutDayPlanSummary` fields (`id`, `name`, `dayOfWeek`, `numberOfExercisesTotal`, `timeEstimateToFinish`) remain unchanged in shape.
