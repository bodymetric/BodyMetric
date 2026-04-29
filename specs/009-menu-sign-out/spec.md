# Feature Specification: Home Menu — Sign Out ("Exit")

**Feature Branch**: `009-menu-sign-out`  
**Created**: 2026-04-27  
**Status**: Draft  
**Input**: User description: "The last item on menu must be 'Exit' and when pressed must logoff the user from Google and remove refresh token and session token."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sign out from the home menu (Priority: P1)

A signed-in user opens the home dropdown menu and taps the "Exit" item at the bottom of the list. The app signs the user out of their account, removes all session credentials from the device, and returns them to the login screen. The user cannot access any authenticated area of the app until they sign in again.

**Why this priority**: Sign-out is the primary security control for ending a session. Without it, users have no way to end their authenticated session from within the app, which is a security and usability gap.

**Independent Test**: Open the menu while authenticated, tap "Exit", and verify: (1) the app shows the login screen, (2) reopening the app does not restore the previous session.

**Acceptance Scenarios**:

1. **Given** the user is authenticated and the home menu is open, **When** the user taps "Exit", **Then** the app signs the user out, removes all session credentials, and navigates to the login screen.
2. **Given** the user has tapped "Exit" and is now on the login screen, **When** the user re-opens the app without signing in again, **Then** the login screen is shown and no prior session is restored.
3. **Given** the home menu is open, **When** the user views the menu items, **Then** "Exit" appears as the last item in the list.

---

### User Story 2 - Sign-out is non-destructive to user data (Priority: P2)

The sign-out action removes only session credentials from the device. The user's workout data, plan history, and profile information stored on the server are unaffected. When the user signs back in, all their data is still accessible.

**Why this priority**: Users must be confident that signing out is a safe, reversible action and does not delete their fitness data.

**Independent Test**: Sign out, sign back in with the same account, and verify that all previously visible workout data and profile information is still accessible.

**Acceptance Scenarios**:

1. **Given** the user has workout plans and profile data, **When** they sign out via "Exit" and sign back in, **Then** all their data is still visible and accessible.
2. **Given** the user signs out, **When** they return to the login screen, **Then** no personal data or credentials are visible to anyone who picks up the device without authenticating.

---

### Edge Cases

- What happens if the sign-out process fails (e.g., no network)? The app MUST still remove all session credentials from the device and navigate to the login screen, even if the remote session revocation request cannot be completed. The user must not remain in an authenticated state.
- What happens if the user taps "Exit" multiple times rapidly? Only one sign-out operation must execute; the app must not navigate to the login screen multiple times or enter an inconsistent state.
- What happens if the app is closed during the sign-out process? On next launch, the app must detect the absence of valid credentials and show the login screen.
- What happens if no network is available when "Exit" is tapped? The local session must still be terminated and all local credentials removed. The user is returned to the login screen regardless.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The home dropdown menu MUST display "Exit" as its final (bottom-most) item.
- **FR-002**: The "Exit" item MUST be visually distinct from the navigable menu items but remain clearly legible (e.g., different weight, label colour within the grayscale palette, or a separator above it).
- **FR-003**: When the user taps "Exit", the app MUST sign the user out of their account with the identity provider.
- **FR-004**: When the user taps "Exit", the app MUST remove all session credentials stored locally on the device.
- **FR-005**: After sign-out completes, the app MUST navigate the user to the login screen.
- **FR-006**: After sign-out, the app MUST NOT allow the user to navigate back to any authenticated screen without signing in again.
- **FR-007**: If the sign-out process encounters a network error, the app MUST still clear local credentials and navigate to the login screen (local-only sign-out fallback).
- **FR-008**: The "Exit" item MUST NOT be disabled or hidden at any time while the user is authenticated.
- **FR-009**: Only one sign-out operation may run at a time; duplicate taps MUST be ignored while the operation is in progress.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of "Exit" taps result in navigation to the login screen, regardless of network availability.
- **SC-002**: 100% of sign-outs result in complete local credential removal — no session can be restored without re-authenticating.
- **SC-003**: The sign-out action completes and the login screen is visible within 2 seconds of the user tapping "Exit" under normal conditions.
- **SC-004**: User data stored on the server is unaffected by sign-out in 100% of cases — all data is accessible again immediately after re-authentication.
- **SC-005**: The "Exit" item is visible as the last menu item in 100% of authenticated sessions.

## Assumptions

- The app already has an established sign-out capability (used elsewhere in the app, e.g., from the profile tab); this feature exposes it via the home menu rather than introducing a new sign-out mechanism.
- "Remove refresh token and session token" means clearing all locally stored credentials — no data is sent to the server solely for this purpose; any remote session invalidation is a best-effort action.
- No confirmation dialog is required before signing out (the action is reversible — the user can simply sign in again).
- After sign-out, the user lands directly on the login screen with no intermediate screens.
- The sign-out operation does not delete any user data from the server; it only ends the local authenticated session.
