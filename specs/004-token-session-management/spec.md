# Feature Specification: Session Token Management

**Feature Branch**: `004-token-session-management`
**Created**: 2026-04-11
**Status**: Draft
**Input**: User description: "After social login get token and persist only on memmory, make this avaiable during all session. Take refresh token and persist o keychain. If backend return any 401 on status code, use refresh token to get another session token or on 4 minutes and 55 seconds"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Token Acquisition After Login (Priority: P1)

After a user successfully signs in with their social account, the app receives a session token and a refresh token from the identity provider. The session token is held in memory for the duration of the session (not written to disk). The refresh token is stored in secure device storage so it survives app restarts.

**Why this priority**: Without token acquisition, no authenticated request can be made. Everything else depends on this working correctly.

**Independent Test**: Can be fully tested by completing a social login flow and verifying that (a) authenticated API calls succeed during the session and (b) the refresh token is present in secure storage after login.

**Acceptance Scenarios**:

1. **Given** a user completes social login successfully, **When** the app receives the authentication response, **Then** the session token is stored only in memory and is immediately available for use in API calls.
2. **Given** a user completes social login successfully, **When** the app receives the authentication response, **Then** the refresh token is persisted in secure on-device storage.
3. **Given** a user completes social login successfully, **When** the session token is stored, **Then** it is NOT written to disk or any persistent storage layer.

---

### User Story 2 — Authenticated API Requests (Priority: P1)

Every request made to the backend while the user is logged in automatically includes the session token in the request headers, without any manual action required from the user.

**Why this priority**: All protected backend functionality depends on this. Without it, every authenticated screen would fail.

**Independent Test**: Can be fully tested by making any authenticated API call and confirming the authorization header is present and accepted by the backend.

**Acceptance Scenarios**:

1. **Given** a user is logged in with a valid session token, **When** the app makes any request to a protected endpoint, **Then** the request includes the session token as a bearer credential in the authorization header.
2. **Given** a user has no session token (not logged in), **When** the app attempts an authenticated request, **Then** the request is not sent and the user is redirected to login.

---

### User Story 3 — Proactive Token Refresh (Priority: P2)

The app proactively refreshes the session token shortly before it expires, without interrupting the user's experience. Session tokens expire after 5 minutes; the app triggers a refresh at 4 minutes and 55 seconds after the token was issued.

**Why this priority**: Prevents the user from encountering failed requests due to token expiry mid-session. Proactive refresh is a better experience than reactive recovery.

**Independent Test**: Can be fully tested by simulating the passage of 4 minutes 55 seconds and confirming a new session token is acquired and used for subsequent requests.

**Acceptance Scenarios**:

1. **Given** a valid session token has been held in memory for 4 minutes and 55 seconds, **When** the timer fires, **Then** the app uses the refresh token to obtain a new session token silently.
2. **Given** the proactive refresh succeeds, **When** the next API call is made, **Then** it uses the newly acquired session token.
3. **Given** the proactive refresh fails (e.g., refresh token is invalid or expired), **When** the timer fires, **Then** the user is signed out and directed to the login screen.

---

### User Story 4 — Reactive Token Refresh on 401 (Priority: P2)

If any backend request returns a 401 Unauthorized response, the app automatically attempts to obtain a new session token using the stored refresh token, then retries the original request — all without user intervention.

**Why this priority**: Handles edge cases where the server rejects a token before the proactive timer fires (e.g., server-side invalidation, clock skew).

**Independent Test**: Can be fully tested by triggering a 401 response and verifying the app silently refreshes and retries the request.

**Acceptance Scenarios**:

1. **Given** a user is logged in and makes an API request, **When** the backend returns 401, **Then** the app uses the refresh token to request a new session token.
2. **Given** the reactive refresh succeeds, **When** the session token is renewed, **Then** the original request is retried automatically and succeeds.
3. **Given** the reactive refresh fails (refresh token expired or revoked), **When** a 401 is received, **Then** the user is signed out and directed to the login screen.
4. **Given** a reactive refresh is already in progress, **When** another request also receives a 401, **Then** the second request waits for the in-progress refresh and reuses the new token (no double-refresh).

---

### User Story 5 — Session Cleanup on Logout (Priority: P1)

When a user explicitly signs out, both the in-memory session token and the persisted refresh token are completely removed. No credentials remain accessible after logout.

**Why this priority**: Security requirement. Credentials left behind after logout are a serious data exposure risk.

**Independent Test**: Can be fully tested by signing out and confirming that subsequent authenticated requests fail and no token is found in secure storage.

**Acceptance Scenarios**:

1. **Given** a logged-in user taps the logout button, **When** sign-out completes, **Then** the session token is cleared from memory.
2. **Given** a logged-in user taps the logout button, **When** sign-out completes, **Then** the refresh token is deleted from secure on-device storage.
3. **Given** a user has logged out, **When** the app is relaunched, **Then** the user sees the login screen and no session token is available.

---

### Edge Cases

- What happens when the refresh token itself has expired at app relaunch? (User must re-authenticate from scratch.)
- What if both the proactive timer and a 401 response trigger a refresh simultaneously? (Only one refresh request should be issued.)
- What if the social identity provider does not return a refresh token for a particular login flow?
- What if the user force-quits the app during a token refresh operation?
- What happens to the proactive timer when the app is backgrounded for longer than 5 minutes?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: After a successful social login, the system MUST store the session token in memory only — it MUST NOT be written to disk or any persistent storage.
- **FR-002**: After a successful social login, the system MUST persist the refresh token in secure on-device storage (survives app restarts).
- **FR-003**: The system MUST include the in-memory session token as a bearer credential on every authenticated API request.
- **FR-004**: The system MUST proactively refresh the session token 4 minutes and 55 seconds after the current session token was issued.
- **FR-005**: The system MUST use the stored refresh token to obtain a new session token whenever the backend returns a 401 Unauthorized response.
- **FR-006**: The system MUST retry the original failed request automatically after a successful reactive token refresh.
- **FR-007**: The system MUST prevent duplicate simultaneous refresh attempts — if a refresh is already in progress, subsequent 401-triggered refreshes MUST wait for the in-progress refresh to complete and reuse the resulting token.
- **FR-008**: If a token refresh fails (proactive or reactive), the system MUST sign the user out and clear all credentials.
- **FR-009**: On explicit user logout, the system MUST clear the session token from memory AND delete the refresh token from secure storage.
- **FR-010**: Session tokens and refresh tokens MUST never appear in application logs or diagnostic traces.

### Key Entities

- **Session Token**: Short-lived credential issued after login; authorizes API requests; held in memory only; expires after 5 minutes.
- **Refresh Token**: Long-lived credential used to obtain new session tokens; persisted in secure on-device storage; deleted on logout or expiry.
- **Token Refresh Operation**: The act of exchanging a refresh token for a new session token; can be triggered proactively (timer at 4:55) or reactively (401 response).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After social login, all authenticated requests succeed without any manual token management by the user.
- **SC-002**: The session token is not discoverable in any persistent storage location after login (verified by inspection).
- **SC-003**: The app silently renews the session token at the 4-minute-55-second mark — users experience no interruption or re-authentication prompt during a valid session.
- **SC-004**: When the backend returns a 401, the app transparently retries the original request after a token refresh — the user never sees an authentication error during a valid session.
- **SC-005**: After logout, no token or credential remains in memory or on-device storage (verified by inspection).
- **SC-006**: Under concurrent 401 responses, exactly one refresh request is issued — no duplicate token refresh calls reach the backend.

## Assumptions

- The social identity provider (Google Sign-In) issues both a session token and a refresh token upon successful authentication.
- Session tokens expire after exactly 5 minutes; the 4:55 proactive refresh timer is calculated from the moment the new token is stored in memory.
- The backend has a dedicated token refresh endpoint that accepts the refresh token and returns a new session token.
- If the backend does not return a refresh token (e.g., token-less provider flows), the user will need to re-authenticate manually — this scenario is out of scope for v1.
- App-backgrounding behavior: if the proactive timer fires while the app is backgrounded, the refresh will occur when the app returns to foreground. If more than 5 minutes have elapsed since the last token was issued, the first authenticated request will receive a 401 and trigger the reactive refresh path.
- Jailbroken/rooted device behavior is out of scope; secure storage is assumed to function as designed on standard devices.
