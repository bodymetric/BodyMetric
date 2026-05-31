# Feature Specification: Wizard Step 2 — Live Exercise Catalog

**Feature Branch**: `012-wizard-exercise-catalog`  
**Created**: 2026-05-01  
**Status**: Draft  
**Input**: User description: "In the second screen of the Workout Plan wizard, load the exercise list for the ExerciseBlockPlan combo boxes from GET /api/exercises. Exercises are grouped by muscle group. All combo boxes share the same list. The endpoint is called only once when the screen opens."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See real exercises in the exercise picker (Priority: P1)

When a user opens the day configuration screen (step 2) of the New Plan wizard, the exercise selector in each exercise block shows a real, up-to-date list of exercises retrieved from the app's catalogue. Exercises are organised by muscle group so the user can quickly find what they need.

**Why this priority**: Without real exercises the user cannot meaningfully configure any exercise block. The static placeholder list currently in the app is not useful for real workout planning.

**Independent Test**: Open wizard step 2, tap the exercise selector on any block, and verify that exercises loaded from the server appear grouped by muscle group (e.g., "Back" group contains "Barbell Row").

**Acceptance Scenarios**:

1. **Given** the user opens the day configuration screen, **When** the exercise list has loaded, **Then** the exercise selector in every block shows real exercises organised into named muscle groups.
2. **Given** the exercise list has loaded, **When** the user taps the exercise selector for any block, **Then** exercises are visible grouped by their muscle group (e.g., "Back", "Biceps").
3. **Given** multiple exercise blocks exist on the screen, **When** the user opens any of the pickers, **Then** all pickers show the same complete exercise list.

---

### User Story 2 - Exercise list loads once and is shared (Priority: P2)

The exercise catalogue is fetched from the server exactly once when the day configuration screen first opens. Every exercise selector on that screen reuses the same in-memory list — no additional server calls are made when the user adds more exercise blocks or opens different pickers.

**Why this priority**: Fetching the same static catalogue once per block would be wasteful and could cause noticeable delays as the user adds exercises. Single-load is critical for a smooth experience.

**Independent Test**: Open step 2, add three exercise blocks, open each picker in sequence — verify exactly one server request was made for the exercise catalogue, not three.

**Acceptance Scenarios**:

1. **Given** the user opens the day configuration screen, **When** the screen loads, **Then** exactly one request is made to retrieve the exercise catalogue regardless of how many exercise blocks are present.
2. **Given** the exercise list is already loaded, **When** the user adds an additional exercise block, **Then** no new request is made for the exercise catalogue.
3. **Given** the exercise list is loading, **When** a second picker is opened before loading completes, **Then** both pickers use the same result once loading completes.

---

### User Story 3 - Graceful handling when the exercise list cannot be loaded (Priority: P3)

If the exercise catalogue cannot be retrieved (network error or server error), the user sees a clear message and can retry. The screen does not crash or silently show an empty picker.

**Why this priority**: Silent failures leave the user unable to configure their workout with no explanation.

**Independent Test**: Simulate a network failure, open step 2, and verify an error message appears with a way to retry.

**Acceptance Scenarios**:

1. **Given** the server returns an error when loading exercises, **When** the user opens the day configuration screen, **Then** a user-friendly error message is displayed.
2. **Given** an error is shown, **When** the user dismisses or retries, **Then** a new attempt to load exercises is made.
3. **Given** the exercise list is loading, **When** the user taps the exercise selector before loading completes, **Then** a loading state is shown rather than an empty list.

---

### Edge Cases

- What happens if the exercise catalogue is empty (server returns an empty array)? The picker opens but shows no exercises; the user cannot select an exercise until the catalogue has content.
- What happens if a muscle group name is missing or blank? The exercises are still shown; groups with blank names are displayed without a header or under a generic label.
- What happens if the user navigates away from step 2 and comes back? The catalogue is re-fetched on re-entry to ensure fresh data.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When the day configuration screen opens, the system MUST initiate a single request to retrieve the complete exercise catalogue.
- **FR-002**: While the exercise catalogue is loading, the exercise selectors MUST display a loading indicator rather than an empty or broken state.
- **FR-003**: Once the catalogue is loaded, every exercise selector on the screen MUST display the full list of exercises organised by muscle group.
- **FR-004**: Each muscle group MUST appear as a named section heading in the exercise selector, with its exercises listed below it.
- **FR-005**: Each exercise MUST be identified by a stable numeric identifier and displayed using its human-readable name.
- **FR-006**: All exercise selectors on the same screen instance MUST share the single loaded catalogue — no duplicate requests.
- **FR-007**: If the catalogue request fails, the system MUST display a user-friendly error message and MUST NOT show a broken or empty picker without explanation.
- **FR-008**: The system MUST NOT make an additional catalogue request when the user adds a new exercise block to the same screen.

### Key Entities

- **Exercise Group**: A named collection of exercises sharing a common muscle group. Attributes: group name (e.g., "back", "biceps").
- **Exercise**: A single training movement. Attributes: stable numeric identifier, human-readable name. Belongs to one Exercise Group.
- **Exercise Catalogue**: The complete set of Exercise Groups and their Exercises, retrieved once per screen visit and shared across all exercise selectors on that screen.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The exercise catalogue appears in all pickers within 2 seconds of the screen opening under normal network conditions.
- **SC-002**: Exactly 1 catalogue request is made per screen visit, regardless of how many exercise blocks are present or added.
- **SC-003**: 100% of exercise selectors on the screen show the same complete grouped list when the catalogue has loaded successfully.
- **SC-004**: When the catalogue fails to load, a visible error message appears within 300 ms of the failure being detected.
- **SC-005**: Users can successfully select an exercise from the live catalogue in under 30 seconds from opening the day configuration screen.

## Assumptions

- The exercise catalogue is considered static for the duration of a single screen visit; it does not need to refresh while the screen is open.
- The catalogue is re-fetched each time the user navigates to the day configuration screen (not globally cached across wizard sessions).
- The muscle group names from the server are used directly as section titles; no client-side renaming or translation is required.
- The user is already authenticated when reaching step 2; the authenticated network layer handles token injection automatically.
- The exercise picker UI already exists as a bottom-sheet component; this feature populates it with server data instead of a static local list.
