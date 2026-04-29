# Quickstart: Home Menu — Sign Out ("Exit")

**Feature**: `009-menu-sign-out`  
**Date**: 2026-04-27

---

## What This Feature Adds

1. **"Exit" menu item** — appended to `HomeMenuItem.catalog` (8th entry, `isSignOut: true`, `isSeparatorAbove: true`)
2. **`onSignOut` callback** — threaded from `MainTabView` → `TodayView` → `HomeMenuView`
3. **Visual treatment** — `Divider()` above "Exit" row; `GrayscalePalette.secondary` text + icon

---

## Modified Files

| File | Change |
|------|--------|
| `Features/Workout/Models/HomeMenuModels.swift` | Add `isSignOut: Bool = false` + `isSeparatorAbove: Bool = false`; append "exit" entry to catalog |
| `Features/Workout/Views/Components/HomeMenuView.swift` | Add `var onSignOut: (() -> Void)? = nil`; handle isSignOut taps; render `Divider()` when `isSeparatorAbove`; update label style for exit row |
| `Features/Workout/Views/TodayView.swift` | Add `let onSignOut: @escaping () -> Void`; pass to `HomeMenuView` |
| `Features/Navigation/MainTabView.swift` | Pass `onSignOut: { [authService] in Task { try? await authService.signOut() } }` to `TodayView` |

---

## HomeMenuModels.swift changes

```swift
// Add to HomeMenuItem:
let isSignOut: Bool
let isSeparatorAbove: Bool

// New catalog entry (append after "settings"):
HomeMenuItem(
    id: "exit",
    label: "Exit",
    subtitle: "Sign out of your account",
    iconName: "rectangle.portrait.and.arrow.right",
    isActive: true,
    isPrimary: false,
    destination: nil,
    isSignOut: true,
    isSeparatorAbove: true
)

// All existing entries get isSignOut: false, isSeparatorAbove: false (default args)
```

---

## HomeMenuView.swift changes

```swift
// New parameter (optional, default nil)
var onSignOut: (() -> Void)? = nil

// In menuItemRow(_:):
// Before rendering the row, if isSeparatorAbove:
if item.isSeparatorAbove {
    Divider()
        .background(GrayscalePalette.separator)
        .padding(.horizontal, 6)
}

// Button action for sign-out item:
if item.isSignOut {
    Logger.info("menu_sign_out_tapped")    // Principle IV trace
    isPresented = false
    onSignOut?()
} else {
    // existing navigation logic
}

// Label style for sign-out row:
// Use GrayscalePalette.secondary for both label and subtitle text
// (existing items use GrayscalePalette.primary for label)
```

---

## TodayView.swift changes

```swift
// Add parameter:
let onSignOut: @escaping () -> Void

// Pass to HomeMenuView:
HomeMenuView(
    isPresented: $menuOpen,
    activeDestination: .today,
    userName: userName,
    onNavigate: { ... },
    onSignOut: onSignOut      // new
)
```

---

## MainTabView.swift changes

```swift
// In TabContent, TodayView call:
TodayView(
    workout: .mockToday,
    streak: .mockStreak,
    userName: profileStore.name ?? "You",
    networkClient: networkClient,
    onSignOut: { [authService] in       // new
        Task { try? await authService.signOut() }
    }
)
```

---

## Interaction Trace Events

| Event | When |
|-------|------|
| `menu_sign_out_tapped` | "Exit" item is tapped (logged in `HomeMenuView`) |
| `tokens_cleared_on_logout` | End of `AuthService.signOut()` (already exists) |

---

## Testing Guide

### Updated assertions in `HomeMenuModelsTests.swift`

| Test | Before | After |
|------|--------|-------|
| `test_catalog_containsExactlySevenItems` | count == 7 | count == 8 |
| `test_catalog_exactlyTwoItemsAreActive` | count == 2 | count == 3 |
| (new) `test_catalog_exitItemIsLast` | — | last item id == "exit" |
| (new) `test_catalog_exitItemIsSignOut` | — | exit.isSignOut == true |
| (new) `test_catalog_exitItemHasSeparator` | — | exit.isSeparatorAbove == true |
| (new) `test_catalog_exitItemHasNilDestination` | — | exit.destination == nil |

### AuthService.signOut already tested

`BodyMetricTests/Services/AuthServiceTests.swift` already verifies that `signOut()` clears access token, deletes refresh token, and sets `isAuthenticated = false`. No new service tests required.
