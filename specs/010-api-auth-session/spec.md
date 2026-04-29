# Feature Specification: Authenticated API Request Handling

**Feature Branch**: `010-api-auth-session`  
**Created**: 2026-04-28  
**Status**: Draft  
**Input**: User description: "Implement authenticated API request handling with Bearer token injection (with named exceptions for auth/public paths), secure Keychain token persistence, 401 automatic refresh with retry, and forced logout on refresh failure."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Seamless session continuation when a token expires (Priority: P1)

A signed-in user is actively using the app. Their session token expires mid-use. When the app makes the next server request it receives an authentication error, silently obtains a new token in the background, and retries the request. The user sees their data appear normally — no logout, no error message, no disruption.

**Why this priority**: Token expiry is a routine event. Without transparent refresh, every token expiry would interrupt the user with a forced login, destroying the user experience. This is the most critical behaviour to get right.

**Independent Test**: Configure a token that expires in seconds, wait for expiry, trigger any authenticated action, and verify the app continues working without displaying an error or navigating to the login screen.

**Acceptance Scenarios**:

1. **Given** the user has a valid refresh token and an expired session token, **When** the user triggers any authenticated action, **Then** the system obtains a new session token, retries the request, and presents the result to the user without any visible disruption.
2. **Given** a token refresh succeeds, **When** the system stores the new tokens, **Then** the new session token and refresh token replace the previous values and are available for all subsequent requests.
3. **Given** a token refresh returns new tokens, **When** the system retries the original request, **Then** the response to the user is identical to what they would have received had the session never expired.

---

### User Story 2 - Session persists across app restarts (Priority: P2)

A user signs in once and then closes the app. When they reopen it later, they are still logged in — their session credentials were stored securely on the device and are retrieved automatically. The user does not need to sign in again unless their session has been explicitly ended.

**Why this priority**: Requiring users to sign in on every app launch is a major usability failure. Persisted tokens are foundational to any usable authenticated experience.

**Independent Test**: Sign in, force-quit the app, reopen it, and verify that any authenticated screen loads without prompting the user to sign in again.

**Acceptance Scenarios**:

1. **Given** the user signed in previously, **When** they reopen the app, **Then** the session is restored and no sign-in screen is shown.
2. **Given** the app stores tokens, **When** another app on the same device attempts to access those tokens, **Then** it cannot — the tokens are protected by the device's secure storage.

---

### User Story 3 - Graceful forced logout when the session cannot be renewed (Priority: P3)

A user's session has fully expired and the refresh token is also invalid (e.g., they have been signed out remotely, or too much time has passed). When the app detects this, it clears all stored credentials and takes the user to the login screen with no residual session data.

**Why this priority**: If the session cannot be renewed, keeping the user on an authenticated screen would be deceptive and insecure. The app must fail gracefully and restart the session cleanly.

**Independent Test**: Invalidate both tokens server-side, trigger an authenticated request, and verify the app navigates to the login screen with no cached credentials remaining.

**Acceptance Scenarios**:

1. **Given** the user's session token is invalid and the refresh request also fails, **When** the refresh failure is detected, **Then** all stored session credentials are removed from the device.
2. **Given** credentials have been cleared after refresh failure, **When** the same condition occurs, **Then** the user is navigated to the login screen.
3. **Given** the user is on the login screen after a forced logout, **When** they sign in successfully, **Then** a fresh session is established with no residual data from the previous session.

---

### Edge Cases

- What happens if the app makes multiple simultaneous requests and all receive a 401? Only one token refresh must occur; once the new tokens are obtained, all waiting requests must be retried with the new token — duplicates must not cause a refresh storm.
- What happens if the refresh endpoint itself returns a network error (timeout, no connectivity)? The system must treat this the same as a 401 — clear credentials and send the user to login; the user must not be left in a broken half-authenticated state.
- What happens if the device loses connectivity mid-request? The failure is surfaced to the user as a network error, not an authentication error, and no token refresh is attempted.
- What happens if the refresh token storage on the device is corrupted or missing? The system detects the absence of a valid refresh token and routes the user to the login screen immediately rather than attempting a refresh.
- What if a request to a public endpoint (sign-in, version check, etc.) receives a 401? No token refresh is attempted; the error is handled as a standard request failure.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: All outgoing requests to protected API endpoints MUST include a session credential in the request header before the request is sent.
- **FR-002**: Requests to authentication endpoints and public endpoints (sign-in, token refresh, version, and health-check paths) MUST NOT include the session credential header.
- **FR-003**: The session token MUST be stored securely on the device such that it cannot be accessed by other applications.
- **FR-004**: The refresh token MUST be stored securely on the device such that it cannot be accessed by other applications.
- **FR-005**: When a protected request receives a session-expired response, the system MUST automatically attempt to obtain a new session token using the stored refresh token before surfacing any error to the user.
- **FR-006**: When a new session token is successfully obtained, the system MUST store it and the accompanying new refresh token, replacing any previously stored values.
- **FR-007**: After a successful token refresh, the system MUST automatically retry the original failed request using the new session token.
- **FR-008**: If the token refresh attempt itself fails with a session-expired response or any unrecoverable error, the system MUST remove all stored session credentials from the device.
- **FR-009**: After clearing credentials following a failed refresh, the system MUST navigate the user to the login screen without requiring any user action.
- **FR-010**: Only one token refresh operation MUST run at a time; if multiple requests fail simultaneously with a session-expired response, the refresh must be serialised and each waiting request retried once the single refresh completes.

### Key Entities

- **Session Token**: A short-lived credential that authorises individual API requests. Stored securely on the device; replaced on every successful token refresh.
- **Refresh Token**: A long-lived credential used exclusively to obtain a new session token. Stored securely on the device; replaced on every successful token refresh.
- **Token Pair**: The combination of a session token and a refresh token issued together; both must be updated atomically when refreshed.
- **Protected Endpoint**: Any API path that requires a valid session credential. All paths except explicitly exempted ones (authentication and public paths).
- **Exempt Endpoint**: An API path that does not require a session credential (e.g., sign-in, token-refresh, version queries, public queries).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of protected API requests include a valid session credential in the request header.
- **SC-002**: 100% of requests to exempt paths are sent without a session credential header.
- **SC-003**: Token refresh is transparent to the user in 100% of cases where the refresh succeeds — no visible error or navigation change.
- **SC-004**: After a failed refresh, credentials are removed and the user reaches the login screen within 2 seconds of the failure being detected.
- **SC-005**: Session credentials survive an app restart and are available for authenticated requests in 100% of cases where the session has not expired.
- **SC-006**: No more than one token refresh request is sent to the server regardless of how many simultaneous requests receive a session-expired response.

## Assumptions

- The "session token" referred to in this spec is the same concept as the "access token" / "id token" used elsewhere in the project; the spec uses the term from the API contract.
- The token refresh endpoint is on the same BodyMetric backend that handles all other authenticated API calls.
- The exempted path prefixes (`/api/auth/`, `/q/`, `/version`) are comprehensive — no other public paths require special handling.
- Token expiry is detected exclusively via server-side 401 responses; the client does not check token expiry locally before sending.
- On a successful refresh, both a new session token and a new refresh token are returned and must be stored; the previous pair is no longer valid.
- A single retry is sufficient after a successful refresh; the app does not retry indefinitely.
- The secure device storage used is the platform's standard encrypted credential store (Keychain on iOS).
