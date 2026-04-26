# Feature Specification: Authenticated Area Global Header

**Feature Branch**: `003-authenticated-header`
**Created**: 2026-04-10
**Status**: Draft
**Input**: User description: "During all the logged area the app must has a header in top, with color green dark like a logo in the left with padding left 10px and logout on right, right padding 10px"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Persistent Header Visible Across All Authenticated Screens (Priority: P1)

Every screen the user sees after signing in displays a consistent header bar
at the top of the viewport. The header contains the app logo on the left and
a logout action on the right. The header remains visible regardless of which
screen the user navigates to within the authenticated area.

**Why this priority**: The header is a global navigation affordance. Without
it, the authenticated area has no consistent identity or exit point.

**Independent Test**: Sign in → verify header appears on the home screen →
navigate to any other authenticated screen → verify header is still present
and identical.

**Acceptance Scenarios**:

1. **Given** a user has successfully signed in,
   **When** any authenticated screen is displayed,
   **Then** a header bar is visible at the top containing the app logo on the
   left and a logout control on the right.

2. **Given** the header is displayed,
   **When** the user taps the logout control,
   **Then** the user is signed out and navigated back to the login screen.

3. **Given** the header is displayed,
   **When** the user rotates the device or changes Dynamic Type size,
   **Then** the header remains correctly laid out with logo on the left and
   logout on the right, with appropriate spacing.

---

### User Story 2 - Header Logo Matches App Brand (Priority: P2)

The logo displayed in the header is the same logo used on the splash screen,
scaled appropriately to fit the header height without clipping or distortion.

**Why this priority**: Visual consistency between the splash screen and the
authenticated area reinforces brand identity.

**Independent Test**: Compare the header logo to the splash screen logo —
both must use the same image asset, correctly scaled.

**Acceptance Scenarios**:

1. **Given** the header is displayed,
   **When** the user views the logo on the left,
   **Then** the logo is the same image used on the splash screen, scaled to
   fit the header height with 10 points of leading padding.

---

### Edge Cases

- What happens when the user is mid-navigation (e.g., a screen transition) — does the header remain stable?
- How does the header behave if the logout action fails (network error)?
- What if the logo image asset is unavailable — does the header degrade gracefully?
- Does the header respect the iOS safe area (notch, Dynamic Island)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The header MUST be displayed on every screen within the authenticated area, from the moment the user signs in until sign-out.
- **FR-002**: The header MUST display the app logo on the left side with 10 points of leading padding.
- **FR-003**: The header MUST display a logout control on the right side with 10 points of trailing padding.
- **FR-004**: Tapping the logout control MUST sign the user out and return them to the login screen.
- **FR-005**: The header MUST respect the iOS safe area insets (notch, Dynamic Island, status bar).
- **FR-006**: The header background MUST use a dark grayscale color (near-black) consistent with the app's grayscale visual design.
- **FR-007**: If the logout action fails, the header MUST remain visible and the user MUST see an error indication without being signed out unintentionally.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The header is visible on 100% of authenticated screens with no authenticated screen missing the header.
- **SC-002**: The logo and logout control are correctly positioned (logo left, logout right) on all supported iOS device sizes including the smallest and largest supported screen.
- **SC-003**: Tapping logout completes the sign-out flow and lands the user on the login screen within 2 seconds under normal network conditions.
- **SC-004**: The header layout does not break or overflow at any Dynamic Type accessibility size setting.

## Assumptions

- The header background uses `GrayscalePalette.primary` (near-black), fully compliant with Constitution Principle VI.
- The header applies to all currently implemented and future authenticated screens (home screen, create-user screen, and any screens added in subsequent features).
- The logo in the header is the same `AppLogo` image asset used on the splash screen, scaled to fit the header height.
- The logout control is a tappable text or icon element — not a full button row.
- The header sits above the main content area and does not scroll with page content.
- Safe area handling follows iOS platform conventions (header appears below the status bar / Dynamic Island).
