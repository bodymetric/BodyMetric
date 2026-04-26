# Feature Specification: User Profile Fetch & Display

**Feature Branch**: `002-user-profile-fetch`
**Created**: 2026-04-09
**Status**: Draft
**Input**: User description: "After successful login via Google, with email from Google request: https://api.bodymetric.com.br/api/users?email=[EMAIL_FROM_GOOGLE]. Take the weight and height and persist in storage with email. If the user already logged in and do not have weight or height make the same request with email saved and persist height, weight. I wanna to print email, height, weight on home screen"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First Login Profile Hydration (Priority: P1)

A user who has just signed in with Google for the first time has their profile
data (weight, height) automatically fetched from the BodyMetric API using the
email obtained from Google. The data is persisted locally so it survives app
restarts. The home screen immediately shows the user's email, weight, and height.

**Why this priority**: This is the core user journey — without profile data,
the home screen is empty and the app delivers no value on first session.

**Independent Test**: Can be fully tested by completing a Google Sign-In on a
fresh install and verifying the home screen shows correct email, weight, and
height without any manual input.

**Acceptance Scenarios**:

1. **Given** a user completes Google Sign-In for the first time,
   **When** the app receives a valid Google email,
   **Then** the app queries the BodyMetric API with that email, receives weight
   and height, persists all three values, and displays them on the home screen.

2. **Given** the API returns a valid user profile with weight and height,
   **When** the response is received,
   **Then** the values are stored locally tied to the user's email and survive
   an app restart.

3. **Given** a user completes Google Sign-In,
   **When** the API returns an error or the device is offline,
   **Then** the home screen shows the email but displays a clear message
   indicating weight and height could not be loaded, without crashing.

---

### User Story 2 - Returning User with Missing Profile Data (Priority: P2)

A user who was previously signed in (session restored) but whose local storage
lacks weight or height (e.g., API was unavailable on first login, or storage
was partially cleared) is automatically re-queried against the API to fill the
missing fields. The home screen then shows the complete profile.

**Why this priority**: Ensures the app self-heals missing data on subsequent
launches without forcing the user to sign out and back in.

**Independent Test**: Can be tested by simulating a returning user whose local
profile is missing weight or height; verify the app fetches and fills the gaps
on launch, then displays the complete data on the home screen.

**Acceptance Scenarios**:

1. **Given** a returning user whose email is in local storage but weight or
   height (or both) are absent,
   **When** the app launches and restores the session,
   **Then** the app queries the API with the stored email, persists the
   returned weight and height, and displays all three fields on the home screen.

2. **Given** a returning user with complete local profile data (email, weight,
   height all present),
   **When** the app launches,
   **Then** the app displays the locally stored data immediately without making
   an API request.

---

### User Story 3 - Home Screen Profile Display (Priority: P3)

A signed-in user can always see their email, weight, and height on the home
screen as a persistent profile summary.

**Why this priority**: Provides immediate feedback that the app has loaded the
correct account data and gives the user a quick health snapshot.

**Independent Test**: Can be tested independently by pre-populating local
storage with known email/weight/height values and verifying the home screen
renders all three fields correctly.

**Acceptance Scenarios**:

1. **Given** local storage contains email, weight, and height,
   **When** the user navigates to the home screen,
   **Then** the screen displays the email, weight (with unit), and height
   (with unit) in a clear, readable layout.

2. **Given** weight or height is not yet available,
   **When** the user navigates to the home screen,
   **Then** the screen shows the email and a placeholder/loading state for
   the missing field(s).

---

### Edge Cases

- What happens when the API returns a user record with null weight or null height?
- How does the system behave when Google Sign-In returns an email but the API
  has no matching user record (404)?
- What if local storage write fails after a successful API response?
- How does the app handle an expired or revoked Google session on relaunch?
- What if the API is reachable but returns a malformed response (missing fields)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: After a successful Google Sign-In, the system MUST extract the
  authenticated user's email address from the Google identity token.
- **FR-002**: The system MUST query `https://api.bodymetric.com.br/api/users`
  with the authenticated email as a query parameter immediately after sign-in.
- **FR-003**: The system MUST extract weight and height from the API response
  and persist them locally alongside the user's email.
- **FR-004**: On each app launch with a restored session, the system MUST check
  whether weight or height is missing from local storage; if either is absent,
  the system MUST re-query the API using the stored email.
- **FR-005**: The home screen MUST display the authenticated user's email,
  weight (with unit), and height (with unit).
- **FR-006**: If the API is unavailable or returns an error, the system MUST
  surface a non-blocking error state on the home screen without hiding the
  email or crashing the app.
- **FR-007**: Persisted profile data MUST survive app termination and relaunch.
- **FR-008**: If local storage already contains complete profile data (email,
  weight, and height), the system MUST NOT make a redundant API request on
  relaunch.

### Key Entities

- **UserProfile**: Represents the authenticated user's fetched data.
  Key attributes: email (unique identifier), weight (numeric value + unit),
  height (numeric value + unit).
- **ProfileStore**: Local persistence container that holds the current user's
  email, weight, and height. Tied to a single signed-in account at a time.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The home screen displays the user's email, weight, and height
  within 3 seconds of a successful Google Sign-In on a supported device with
  a standard mobile data connection.
- **SC-002**: On subsequent launches with complete local data, profile
  information appears on the home screen within 500 ms (no network request
  required).
- **SC-003**: 100% of successful API responses result in persisted data that
  survives an app restart.
- **SC-004**: When the API is unreachable, the app remains usable (no crash)
  and the email is always visible; an informative message is shown for missing
  fields.
- **SC-005**: The re-fetch flow for missing data (User Story 2) completes
  without requiring any user action — fully automatic.

## Assumptions

- The BodyMetric API endpoint `GET /api/users?email=<value>` is stable and
  returns a JSON object containing at minimum `weight` and `height` fields
  when a matching user exists.
- Weight and height units are provided by the API (not inferred by the client);
  the client displays whatever unit string the API returns.
- A single device is used by one Google account at a time; multi-account
  switching on the same device is out of scope.
- The Google Sign-In session restoration mechanism already implemented in
  feature 001 is reused; this feature does not change the authentication flow.
- Local persistence uses the same secure storage layer (Keychain or equivalent)
  established in the project's technical stack.
- The API does not require authentication headers beyond the email query
  parameter for this endpoint (if auth headers are needed, this is a dependency
  to resolve in planning).
