# Feature Specification: Automated Training Week Tracking

**Feature Branch**: `014-workout-week-tracking`  
**Created**: 2026-05-02  
**Status**: Draft  
**Input**: User description: "Remove plannedWeekNumber from WorkoutPlan model; system automatically tracks actualWeekNumber. Week 1 on creation, increments when all days are completed. Users never manually set the training week. App removes plannedWeekNumber from all requests and exposes actualWeekNumber in responses."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Training week advances automatically after completing all days (Priority: P1)

A user who has an active workout plan completes every scheduled training day in a single cycle. Without any input from the user, the app shows that they have moved to the next training week. They never had to set or update the week themselves.

**Why this priority**: The core value of this feature is removing manual week tracking. If week progression doesn't work automatically, the entire feature is blocked.

**Independent Test**: Create a plan with 3 training days. Mark all 3 as completed. Verify the current training week has incremented by 1 and all days show as available again for the next cycle.

**Acceptance Scenarios**:

1. **Given** a user has an active plan with 3 training days and all 3 are marked completed, **When** the system detects full cycle completion, **Then** the training week counter increments by 1 and all training days become available for the next cycle.
2. **Given** a user is on training week 5, **When** they complete their last day of the week, **Then** the plan advances to week 6 automatically.
3. **Given** a user creates a new workout plan, **When** the plan is first saved, **Then** the training week starts at 1.

---

### User Story 2 - Current training week is visible to the user (Priority: P2)

A user can see which training week they are currently in whenever they view their workout plan. The week number reflects how many cycles they have completed since starting the plan, not any calendar date.

**Why this priority**: If users cannot see their progress week, the automated tracking provides no visible benefit.

**Independent Test**: Start a new plan (week 1). Complete a full cycle. Verify the app shows "Week 2". Complete another full cycle. Verify the app shows "Week 3".

**Acceptance Scenarios**:

1. **Given** a user has completed 4 full cycles of their plan, **When** they view their workout plan, **Then** the app shows that they are on training week 5.
2. **Given** a new plan was just created, **When** the user views the plan, **Then** training week 1 is displayed.
3. **Given** a user has completed some but not all days in the current cycle, **When** they view the plan, **Then** the current training week number is shown (not yet incremented).

---

### User Story 3 - Starting a new plan resets the training week (Priority: P3)

When a user creates and saves a new workout plan, the new plan becomes the active one and the training week counter resets to 1. History from the previous plan is not carried over.

**Why this priority**: Plan replacement is a natural lifecycle event. Users starting fresh should not inherit the week count from an old plan.

**Independent Test**: Complete 5 cycles on a plan (training week 6). Create a new plan. Verify the training week shows 1 on the new plan.

**Acceptance Scenarios**:

1. **Given** a user has been training on a plan for 10 weeks, **When** they create and save a new workout plan, **Then** the new plan starts at training week 1.
2. **Given** a new plan replaces an old one, **When** the user views their plan, **Then** only the new plan's days and week count are shown.

---

### Edge Cases

- What if a user marks the same day as completed twice in the same cycle? The system must prevent double-completion — a day can only be completed once per cycle.
- What if a user completes days out of order (e.g., day 3 before day 1)? The week advances as long as ALL days are completed in any order.
- What if the plan has only one training day? The week advances every time that single day is completed.
- What if the user never completes all days? The training week does not advance and remains at the current number indefinitely.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST NOT require the user to manually set or update the training week number.
- **FR-002**: When a new workout plan is created, the training week MUST be automatically initialised to 1.
- **FR-003**: Each training day in a plan MUST track whether it has been completed in the current cycle.
- **FR-004**: A training day MUST NOT be countable as completed more than once within the same cycle.
- **FR-005**: When all training days in a plan are marked as completed in the current cycle, the system MUST automatically advance the training week by 1 and reset all days to the incomplete state for the next cycle.
- **FR-006**: The current training week number MUST be exposed in the workout plan data available to the app.
- **FR-007**: The training week number MUST NOT appear in any request sent by the app to create or update a workout plan — it is a server-managed value.
- **FR-008**: When a user creates a new workout plan that replaces the existing active plan, the training week for the new plan MUST start at 1.
- **FR-009**: The app MUST display the current training week number wherever the workout plan status is shown.

### Key Entities

- **Workout Plan**: The user's overall training programme. Contains training days and tracks the current training week (`actualWeekNumber`). Always starts at week 1. Stays active until replaced.
- **Training Day (WorkoutDayPlan)**: A single scheduled training session within a plan. Tracks whether it has been completed in the current cycle. Resets to incomplete when the cycle advances.
- **Training Cycle**: One full pass through all training days in a plan. Completing a cycle causes the training week to increment.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of newly created workout plans begin at training week 1 with no user action required.
- **SC-002**: 100% of complete cycles (all training days completed) result in the training week incrementing by exactly 1.
- **SC-003**: 100% of training day completions within a cycle are idempotent — marking the same day completed twice in one cycle has no effect on the week counter.
- **SC-004**: The current training week number is visible to the user within 2 seconds of opening the workout plan view.
- **SC-005**: 100% of new plan creation events reset the training week to 1 without requiring any additional user action.

## Assumptions

- The training week is a cycle counter (1, 2, 3 …), not a calendar week. Week 3 means the user has completed 2 full training cycles.
- The server is responsible for all training week tracking logic; the mobile app only reads `actualWeekNumber` from the server response and removes `plannedWeekNumber` from all outgoing requests.
- A "complete cycle" means every training day in the plan has been marked completed at least once since the last cycle reset.
- The day completion state is tracked on the server; the app does not locally manage cycle state.
- When a new plan is created, the previous plan is replaced immediately — there is no concurrent active plan.
- The `plannedWeekNumber` field (previously used for day-of-week identification, 1–7) is completely removed from all request and response payloads.
- Day identification continues to use the day-of-week name (e.g., "MONDAY") rather than a numeric week field.
