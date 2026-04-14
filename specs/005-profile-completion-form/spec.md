# Feature Specification: Complete Missing User Profile Data

**Feature Branch**: `005-profile-completion-form`
**Created**: 2026-04-12
**Status**: Draft
**Input**: User description: "Feature: Complete missing user profile data. If a user record is missing name, height, or weight, redirect to a profile completion form. Email prefilled and read-only. Submit via POST /api/users with loading/success/error states."

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Profile Completion Gate (Priority: P1)

A newly signed-in user whose backend record is missing one or more of `name`, `height`, or `weight` is automatically redirected to a profile completion form before they can access the home screen. The form pre-fills their email (read-only), and they must supply all required fields before proceeding.

**Why this priority**: Without this gate, the app may display incomplete or broken profile data on the home screen. This is the core value of the feature — it must work end-to-end before any polish.

**Independent Test**: Simulate a login response where the user object has `name` as null or missing. Verify the app presents the profile completion form instead of the home screen, with the email field pre-populated and read-only.

**Acceptance Scenarios**:

1. **Given** a user signs in and their backend profile is missing `name`, **When** the app processes the login response, **Then** the profile completion form is shown instead of the home screen.
2. **Given** a user signs in and their backend profile is missing `height`, **When** the app processes the login response, **Then** the profile completion form is shown.
3. **Given** a user signs in and their backend profile is missing `weight`, **When** the app processes the login response, **Then** the profile completion form is shown.
4. **Given** a user's profile has all three fields populated, **When** the app processes the login response, **Then** the home screen is shown directly (no redirection).
5. **Given** the profile completion form is open, **When** it renders, **Then** the email field is pre-filled with the user's email and is read-only (non-editable).

---

### User Story 2 — Form Submission with Loading and Success (Priority: P1)

The user fills in name, height, and weight, taps "Update", sees a loading indicator while the request is in-flight, and on HTTP 201 sees a success message before being redirected to the home screen after ~4 seconds.

**Why this priority**: This is the happy path — submitting the form must work correctly and give clear feedback; otherwise the feature is unusable.

**Independent Test**: Render the form with all fields filled. Tap "Update". Mock the backend to return HTTP 201. Verify loading state appears, then success message appears, then home navigation fires after ~4 seconds.

**Acceptance Scenarios**:

1. **Given** all required fields are filled, **When** the user taps "Update", **Then** the button label is hidden and a loading indicator appears inside the button.
2. **Given** the request is in-flight, **When** viewing the button, **Then** it is disabled and cannot be tapped again.
3. **Given** the backend returns HTTP 201, **When** the response is received, **Then** a success message is displayed to the user.
4. **Given** the success message is showing, **When** approximately 4 seconds have elapsed, **Then** the app navigates to the home screen.

---

### User Story 3 — Validation and Error Handling (Priority: P2)

The form prevents submission with invalid data (client-side validation) and gracefully handles backend errors by restoring the button to its original state and showing an error message.

**Why this priority**: Validation protects data integrity; error handling ensures the user is never stuck. Both are important but the core flow (US1 + US2) must work first.

**Independent Test**: Attempt to submit with an empty name field — verify submission is blocked. Then mock the backend to return a non-201 status — verify the loading indicator disappears, "Update" label is restored, and an error message is shown.

**Acceptance Scenarios**:

1. **Given** the name field is empty, **When** the user taps "Update", **Then** submission is blocked and an inline validation message is shown.
2. **Given** the name field exceeds 20 characters, **When** the user taps "Update", **Then** submission is blocked and a validation message is shown.
3. **Given** height is empty or non-positive, **When** the user taps "Update", **Then** submission is blocked and a validation message is shown.
4. **Given** weight is empty or non-positive, **When** the user taps "Update", **Then** submission is blocked and a validation message is shown.
5. **Given** the backend returns an error (non-201), **When** the response is received, **Then** the loading indicator is removed, the "Update" label is restored on the button, and an error message is shown.
6. **Given** an error is shown and the user corrects the form, **When** they tap "Update" again, **Then** a new submission attempt is made normally.

---

### Edge Cases

- What happens when the user's email is nil at the time the form opens? This cannot occur — email is always present from Google Sign-In and is required by the auth flow.
- What if the network call times out? Treated the same as any backend error — loading state cleared, error message shown, user stays on form.
- Can the user dismiss or navigate back from the form? No — the form is a mandatory gate; back navigation and dismiss gestures are disabled.
- What if two or all three fields are missing? The form is shown regardless — all three fields are required whether one or all are missing.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST detect whether the authenticated user's profile is missing `name`, `height`, or `weight` immediately after sign-in.
- **FR-002**: If any of those three fields is missing or null, the app MUST present the profile completion form instead of the home screen.
- **FR-003**: The profile completion form MUST display an email field pre-filled with the authenticated user's email, and that field MUST be read-only.
- **FR-004**: The form MUST require `name` (max 20 characters), `height` (positive number), and `weight` (positive number) before allowing submission.
- **FR-005**: Tapping "Update" MUST hide the button label and display a loading indicator inside the button; the button MUST remain disabled until the request completes.
- **FR-006**: On successful submission (HTTP 201), the app MUST display a success message, then navigate to the home screen after approximately 4 seconds.
- **FR-007**: On failed submission (non-201 or network error), the app MUST display an error message, restore the "Update" button label, remove the loading indicator, and keep the user on the form.
- **FR-008**: Submission MUST send a `POST` request to `/api/users` with body fields `name`, `email`, `height`, and `weight`.
- **FR-009**: The profile completion form MUST NOT be dismissible without completing submission (mandatory gate — no back button, no swipe-to-dismiss).

### Key Entities

- **UserProfile**: Represents the authenticated user's data. Key fields: `id`, `name`, `email`, `height`, `weight`. A profile is considered incomplete when `name`, `height`, or `weight` is null or absent.
- **ProfileCompletionRequest**: The payload sent to `/api/users`. Fields: `name` (String, ≤ 20 characters), `email` (String, valid email format), `height` (positive decimal), `weight` (positive decimal).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users with incomplete profiles are always redirected to the form — zero cases of an incomplete profile reaching the home screen.
- **SC-002**: Users can complete and submit the form in under 2 minutes from first display.
- **SC-003**: The loading indicator appears within 200 ms of tapping "Update".
- **SC-004**: After a successful submission, the user reaches the home screen within 5 seconds (4 s delay + transition).
- **SC-005**: Client-side validation prevents submission of invalid data in 100% of cases (name > 20 chars, non-positive height/weight, empty required fields).

## Assumptions

- The user's email is always available when the form is shown, sourced from the authenticated Google account stored in the app.
- The backend profile data (name, height, weight) is already available in the object returned from the login/exchange response — no extra network call is needed to detect incompleteness.
- Height and weight are decimal numbers (e.g., `182.0`, `82.0`); the form uses a numeric keyboard.
- The form is a one-time gate per session; once the user submits successfully, subsequent sign-ins with a complete profile bypass the form entirely.
- No offline support is required; the form requires an active network connection.
- The "Update" button label is literal — no localization variation is in scope.
