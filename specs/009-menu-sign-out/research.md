# Research: Home Menu — Sign Out ("Exit")

**Feature**: `009-menu-sign-out`  
**Date**: 2026-04-27

## 1. AuthService.signOut() already handles everything

**Decision**: Use `AuthService.signOut()` as-is. No changes to the service layer are needed.

**Rationale**: `AuthService.signOut()` already:
1. Calls `tokenStore.clearAccessToken()` — removes the in-memory access token
2. Calls `keychainService.deleteRefreshToken()` — removes the Keychain refresh token (failure is logged but non-fatal, ensuring sign-out is never blocked by a Keychain error)
3. Calls `GIDSignIn.sharedInstance.signOut()` — ends the Google session
4. Sets `isAuthenticated = false` — triggers `BodyMetricApp` to route back to `LoginView`

This satisfies FR-003 (sign out from identity provider), FR-004 (remove credentials), FR-007 (offline fallback — the Keychain delete still succeeds without network).

**Alternatives considered**:
- Creating a new sign-out method — rejected; `signOut()` is complete and already tested.

---

## 2. Navigation back to login: no additional code needed

**Decision**: `BodyMetricApp.rootView` already observes `authService.isAuthenticated`. When `signOut()` sets it to `false`, SwiftUI automatically transitions to `LoginView`. No programmatic navigation call is needed from the menu.

**Rationale**: The entire authenticated content tree is gated by:
```swift
if authService.isAuthenticated {
    authenticatedContainer  // includes MainTabView + TodayView
} else {
    LoginView(...)
}
```
Setting `isAuthenticated = false` will dismiss `MainTabView`, `TodayView`, `HomeMenuView`, and all other authenticated screens atomically.

**Alternatives considered**:
- Programmatically dismiss all presented views before sign-out — rejected; SwiftUI observability handles this automatically.

---

## 3. "Exit" item placement: separate from the main catalog via Divider

**Decision**: The "Exit" item is appended to `HomeMenuItem.catalog` as the 8th entry. A `Divider()` is rendered in `HomeMenuView` between the 7 existing items and the "Exit" item using a new `HomeMenuItem.isSeparatorAbove: Bool` flag (default `false`, `true` for the "exit" item).

**Rationale**: The spec requires "Exit" as the bottom-most item and visually distinct. A separator above it matches standard iOS patterns (e.g., system menus, Settings). The flag approach avoids hardcoding row indices in the view. An alternative `isDestructive` flag was considered but rejected — the spec does not use the word "destructive" and the grayscale palette cannot use red for destructive actions (Principle VI).

**Alternatives considered**:
- Hardcode a divider after row index 6 — rejected; fragile when catalog changes.
- Separate "signOutItem" property — rejected; adds complexity without benefit.

---

## 4. Sign-out callback threading through view hierarchy

**Decision**: `HomeMenuView` receives `var onSignOut: (() -> Void)? = nil`. `TodayView` receives `let onSignOut: @escaping () -> Void`. `MainTabView` passes `{ [authService] in Task { try? await authService.signOut() } }`.

**Rationale**: This avoids threading `AuthServiceProtocol` through `TodayView` (which doesn't need the full auth contract). A simple closure boundary is idiomatic SwiftUI. The `Task { ... }` wrapper is safe because `authService.signOut()` is `@MainActor` and `Task { }` runs on the caller's actor (MainActor).

**Alternatives considered**:
- Pass `authService` through `TodayView` — rejected; over-exposure of auth contract to a view that doesn't need it.
- Use `@Environment` — rejected; adds boilerplate; the closure is simpler.

---

## 5. Visual treatment: GrayscalePalette.secondary + SF Symbol

**Decision**: The "Exit" row uses `GrayscalePalette.secondary` for both text and icon (instead of `GrayscalePalette.primary`). The icon is `"rectangle.portrait.and.arrow.right"` (same SF Symbol used by the previous logout button in `AppHeader`). No red or other non-grayscale color.

**Rationale**: Principle VI prohibits non-grayscale colors. `secondary` is sufficiently subordinate relative to the `primary`-colored navigation items. The separator above provides the visual separation the spec requires. The icon communicates "leave" semantically without relying on color.

**Alternatives considered**:
- Bold red text — rejected; violates Principle VI.
- `disabled` gray — rejected; "Exit" is active, not disabled.

---

## All NEEDS CLARIFICATION Items

None — all questions resolved via the research above.
