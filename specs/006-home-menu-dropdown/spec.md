# Feature Specification: Home Menu Dropdown

**Feature Branch**: `006-home-menu-dropdown`  
**Created**: 2026-04-25  
**Status**: Draft  
**Input**: User description: "Generate a top-right dropdown menu based on the provided HTML example. The dropdown menu must open when the user taps the logo in the top-right corner. The menu must contain the same elements shown in the provided HTML. Add a menu item named 'New Workout Plan'. When the user taps 'New Workout Plan', navigate to the 'New Plan' wizard."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Open menu and navigate to New Plan wizard (Priority: P1)

A user on the Today (home) screen taps the mascot/logo chip in the top-right corner. A dropdown menu slides in from the top-right with all navigation items listed. The user taps "New Workout Plan" and is taken directly to the New Plan wizard screen.

**Why this priority**: This is the primary reason the menu exists in this iteration — providing a clear, single tap path to create a new workout plan. The menu is the only entry point to the wizard from the home screen.

**Independent Test**: Can be fully tested by launching the app to the Today screen, tapping the mascot chip, tapping "New Workout Plan", and verifying the wizard screen appears.

**Acceptance Scenarios**:

1. **Given** the user is on the Today screen, **When** they tap the mascot chip in the top-right corner, **Then** the dropdown menu appears anchored below the mascot chip with all seven menu items visible.
2. **Given** the menu is open, **When** the user taps "New Workout Plan", **Then** the menu closes and the New Plan wizard screen is presented.
3. **Given** the menu is open, **When** the user taps "Today", **Then** the menu closes and the user remains on the Today screen.

---

### User Story 2 - Dismiss the menu without navigating (Priority: P2)

A user opens the menu but decides not to navigate anywhere. They can dismiss it by tapping the close button inside the menu header, or by tapping anywhere on the dimmed background behind the menu.

**Why this priority**: Users must always have a clear exit from any overlay. Without dismissal, the menu would trap the user.

**Independent Test**: Can be fully tested by opening the menu and dismissing it via the close button, then opening it again and tapping the scrim — verifying the Today screen is returned to in both cases.

**Acceptance Scenarios**:

1. **Given** the menu is open, **When** the user taps the close (×) button in the menu header, **Then** the menu dismisses with an animation and the Today screen is fully interactive again.
2. **Given** the menu is open, **When** the user taps the semi-transparent scrim behind the menu, **Then** the menu dismisses and the Today screen is fully interactive again.

---

### User Story 3 - View coming-soon items without navigating (Priority: P3)

A user sees "My Plans", "History", "Progress", "Profile", and "Settings" listed in the menu. These items are visually distinct from active items (labelled "SOON"), and tapping them has no effect — the menu stays open, no navigation occurs.

**Why this priority**: The full menu surface area must be present for visual completeness and to communicate the app's future roadmap, even though those destinations are not yet implemented.

**Independent Test**: Can be fully tested by opening the menu and tapping each SOON-labelled item, confirming the menu remains open and no screen change occurs.

**Acceptance Scenarios**:

1. **Given** the menu is open, **When** the user taps any item labelled "SOON", **Then** nothing happens — the menu stays open and no navigation occurs.
2. **Given** the menu is open, **When** the user views the item list, **Then** each SOON item is visually distinct from active items (e.g., reduced opacity and a "SOON" badge visible).

---

### Edge Cases

- What happens when the menu is opened while a workout session is in progress? The mascot chip trigger must be available on the Today screen only; it should not interfere with the session flow on other screens.
- What happens if the user rapidly taps the mascot chip multiple times? Only one menu instance must appear — repeated taps must not stack multiple overlays.
- What happens on very small or large display sizes? The menu panel must remain within the phone screen bounds and not clip.
- What happens when the screen orientation changes while the menu is open? The menu must dismiss or reposition correctly (portrait-only app: no action needed).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The mascot chip in the top-right corner of the Today screen MUST be a tappable button that opens the dropdown menu.
- **FR-002**: The dropdown menu MUST appear visually anchored below the mascot chip trigger in the top-right area of the screen.
- **FR-003**: The menu MUST include a header section displaying the app mascot image, the "BodyMetric" app name, the authenticated user's display name, and the app version string.
- **FR-004**: The menu MUST display a close (×) button inside its header that dismisses the menu when tapped.
- **FR-005**: The menu MUST contain exactly the following seven items in order: Today, New Workout Plan, My Plans, History, Progress, Profile, Settings.
- **FR-006**: Each menu item MUST display an icon, a primary label, and a one-line subtitle description.
- **FR-007**: "Today" and "New Workout Plan" MUST be active (tappable and navigable); the remaining five items MUST be marked "SOON" and non-navigable.
- **FR-008**: "New Workout Plan" MUST be visually differentiated as the primary action (e.g., highlighted background or accent color on its icon).
- **FR-009**: Tapping "New Workout Plan" MUST dismiss the menu and navigate the user to the New Plan wizard screen.
- **FR-010**: Tapping "Today" MUST dismiss the menu and keep the user on the Today screen.
- **FR-011**: A semi-transparent scrim MUST cover the entire screen behind the menu while the menu is open; tapping the scrim MUST dismiss the menu.
- **FR-012**: A visual pointer/notch MUST appear at the top of the menu panel, pointing toward the mascot chip trigger.
- **FR-013**: The menu MUST animate when opening (scale from top-right and fade in) and closing (reverse).
- **FR-014**: The currently active screen MUST be visually indicated within the menu (e.g., highlighted or selected state on the matching item).
- **FR-015**: Only one instance of the menu may be shown at a time; rapid repeated taps on the trigger MUST NOT open multiple overlays.

### Key Entities

- **Menu Item**: A navigable or informational entry in the dropdown. Attributes: label, subtitle, icon identifier, active/disabled state, destination screen identifier.
- **Menu**: The overlay container. Attributes: open/closed state, anchor position, currently active screen.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can open the dropdown menu and tap "New Workout Plan" in under 3 seconds from the Today screen.
- **SC-002**: The menu opens and is fully visible within 300 ms of the user tapping the mascot chip.
- **SC-003**: 100% of taps on SOON-labelled items result in no navigation — the menu remains open.
- **SC-004**: The menu is dismissible via the close button or scrim tap in 100% of test cases, leaving the Today screen fully interactive.
- **SC-005**: No duplicate menu overlays can be created regardless of how rapidly the trigger is tapped.

## Assumptions

- The New Plan wizard screen (destination for "New Workout Plan") exists or will be introduced as part of a parallel or subsequent feature; this spec covers navigation to it but not its contents.
- The menu is only accessible from the Today tab's home screen — it is not a global navigation element present on other tabs or child screens.
- The user's display name shown in the menu header is sourced from the existing authenticated profile data (already loaded by the time the Today screen is visible).
- The app version string shown in the menu header is the current marketing version of the app.
- The menu is portrait-only, consistent with the rest of the app.
- Haptic feedback on menu open/close is desirable but not a hard requirement for this iteration.
- The five "SOON" items (My Plans, History, Progress, Profile, Settings) will not provide any navigation in this feature iteration; enabling them is out of scope.
