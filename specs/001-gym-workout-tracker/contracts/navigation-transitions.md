# Navigation & Transition Contract

**Branch**: `001-gym-workout-tracker` | **Date**: 2026-04-04

Defines the navigation architecture, screen ownership, and the animation contract for all screen transitions. All transitions MUST use the values defined here; hardcoded durations or curves elsewhere are a violation of Principle V.

---

## Navigation Architecture

The app uses a single `NavigationStack` per tab, driven by `AppRouter` — a centralised `@Observable` class holding the navigation path for each tab.

```
TabView
├── Tab: Home / Check-In   → NavigationStack (path: AppRouter.workoutPath)
├── Tab: Program           → NavigationStack (path: AppRouter.programPath)
├── Tab: History           → NavigationStack (path: AppRouter.historyPath)
└── Tab: Profile           → NavigationStack (path: AppRouter.profilePath)
```

Modal presentations (sheets) are managed by `AppRouter.presentedSheet: SheetDestination?`.

---

## Screen Inventory

| Screen | Route / Destination | Tab | Presentation |
|---|---|---|---|
| `LoginView` | Root (unauthenticated) | — | Full screen replace |
| `CheckInView` | `.checkIn` | Home | Push |
| `ActiveSessionView` | `.activeSession(sessionId)` | Home | Push (hero expand) |
| `ExerciseLogView` | `.exerciseLog(logId)` | Home | Sheet (`.medium`, `.large`) |
| `SessionCompleteView` | `.sessionComplete(sessionId)` | Home | Sheet (`.large`) |
| `ProgramView` | `.program(programId)` | Program | Push |
| `TrainingDayView` | `.trainingDay(dayId)` | Program | Push |
| `HistoryView` | `.history` | History | Root |
| `ExerciseHistoryView` | `.exerciseHistory(exerciseId)` | History | Push |
| `ProfileView` | `.profile` | Profile | Root |
| `BadgesView` | `.badges` | Profile | Push |

---

## Animation Baseline

All transitions MUST use these values unless a specific override is documented in the screen's ViewMode:

```swift
// Core/Navigation/Transition.swift

extension Animation {
    static let bmSpring = Animation.spring(response: 0.35, dampingFraction: 0.82)
    static let bmFade   = Animation.easeInOut(duration: 0.25)
}
```

| Transition Type | Animation | Notes |
|---|---|---|
| NavigationStack push/pop | `.slide` + `.bmSpring` | Native `navigationTransition(.slide)` on iOS 17; `.zoom` on iOS 18 if available |
| Tab switch | `.bmFade` | Subtle cross-dissolve; native tab bar handles icon animation |
| Hero (card → session) | `matchedGeometryEffect` + `.bmSpring` | `CheckInView` workout card → `ActiveSessionView` |
| Sheet present | Native `.sheet` | SwiftUI default; no custom curve needed |
| Sheet dismiss | Native `.sheet` dismiss | |
| Authentication → main app | `.bmFade` full-screen | `LoginView` fades out; `TabView` fades in |

---

## Transition Definitions

```swift
// Core/Navigation/Transition.swift

extension AnyTransition {
    static var bmSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    static var bmScaleUp: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.92).combined(with: .opacity),
            removal: .scale(scale: 1.05).combined(with: .opacity)
        )
    }
}
```

---

## Navigation Rules

1. `AppRouter` is the single source of truth for navigation state. ViewModels call `router.push(...)` — they do NOT hold navigation state themselves.
2. Views MUST NOT use `@Environment(\.dismiss)` for programmatic navigation; only sheets use it.
3. Back navigation (swipe / back button) is handled natively by `NavigationStack`; no custom overrides.
4. Deep-linking (future): `AppRouter` will handle URL-based path setting. Reserve `navigationDestination` IDs accordingly.
5. Unauthenticated state: `AppEnvironment` observes `AuthService.isAuthenticated` and swaps the root view — NOT via `NavigationStack` push.

---

## Compliance Gate

- All new screens added under `Features/` MUST register their `navigationDestination` in the owning tab's `NavigationStack`.
- Code review MUST verify that no `NavigationLink(destination:)` (deprecated API) is used; only `NavigationLink(value:)` is permitted.
- Any transition that does not use `Animation.bmSpring` or `Animation.bmFade` MUST be documented with a rationale comment.
