# Data Model: Home Menu — Sign Out ("Exit")

**Feature**: `009-menu-sign-out`  
**Date**: 2026-04-27

---

## 1. HomeMenuItem — extended

The `HomeMenuItem` struct gains two new fields:

| New Field | Type | Default | Description |
|-----------|------|---------|-------------|
| `isSignOut` | `Bool` | `false` | `true` only for the "Exit" item; triggers sign-out callback instead of navigation |
| `isSeparatorAbove` | `Bool` | `false` | `true` only for the "Exit" item; renders a `Divider()` above the row in the menu |

All existing catalog entries keep `isSignOut: false` and `isSeparatorAbove: false` via default argument values — no call sites require changes.

### Updated catalog (8 items)

| id | Label | Subtitle | Icon | isActive | isPrimary | isSignOut | isSeparatorAbove |
|----|-------|----------|------|----------|-----------|-----------|-----------------|
| `today` | Today | Your daily workout | `calendar` | ✅ | ❌ | ❌ | ❌ |
| `newPlan` | New Workout Plan | Build a weekly programme | `plus` | ✅ | ✅ | ❌ | ❌ |
| `myPlans` | My Plans | Saved routines | `dumbbell.fill` | ❌ | ❌ | ❌ | ❌ |
| `history` | History | Past sessions | `chart.line.uptrend.xyaxis` | ❌ | ❌ | ❌ | ❌ |
| `progress` | Progress | PRs · volume | `bolt.fill` | ❌ | ❌ | ❌ | ❌ |
| `profile` | Profile | Account · units | `person.circle` | ❌ | ❌ | ❌ | ❌ |
| `settings` | Settings | Preferences | `gearshape.fill` | ❌ | ❌ | ❌ | ❌ |
| `exit` | Exit | Sign out of your account | `rectangle.portrait.and.arrow.right` | ✅ | ❌ | ✅ | ✅ |

**Total items**: 8 (was 7)  
**Active items**: 3 (was 2) — Today, New Workout Plan, Exit  
**Primary items**: 1 (unchanged) — New Workout Plan only

---

## 2. HomeMenuView — new parameter

`HomeMenuView` gains one optional parameter:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `onSignOut` | `(() -> Void)?` | `nil` | Called when "Exit" is tapped; caller dispatches async sign-out |

Existing `onNavigate: (HomeMenuDestination) -> Void` is unchanged.

---

## 3. TodayView — new parameter

`TodayView` gains one parameter:

| Parameter | Type | Description |
|-----------|------|-------------|
| `onSignOut` | `@escaping () -> Void` | Forwarded to `HomeMenuView`; injected from `MainTabView` |

---

## 4. Sign-out state machine (no new state)

The sign-out flow uses existing `AuthService` state:

```
User taps "Exit"
    → HomeMenuView calls onSignOut()
    → MainTabView's closure fires: Task { try? await authService.signOut() }
    → AuthService.signOut():
        1. tokenStore.clearAccessToken()   (in-memory)
        2. keychainService.deleteRefreshToken() (Keychain; failure logged, non-fatal)
        3. GIDSignIn.sharedInstance.signOut()   (Google session)
        4. isAuthenticated = false
    → BodyMetricApp.rootView reacts: shows LoginView
```

No new persisted state. No new error types.
