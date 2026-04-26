# Research: Home Menu Dropdown

**Feature**: `006-home-menu-dropdown`  
**Date**: 2026-04-25

## 1. SwiftUI Dropdown Overlay Pattern

**Decision**: Use a ZStack overlay inside `TodayView`'s `NavigationStack` — not a native `popover` or `sheet`.

**Rationale**: iOS `popover` is designed for iPad and behaves as a sheet on iPhone, losing the top-right anchor. A manual ZStack overlay gives full control over position, animation, and the pointer/notch triangle, exactly matching the HTML prototype's behavior. This is the same technique used by several iOS design systems (e.g., Toucan, Mercury menus).

**Alternatives considered**:
- `.sheet` / `.presentationDetents` — rejected; always slides from the bottom, wrong anchor.
- `.popover` — rejected; becomes full-sheet on iPhone; no custom notch.
- Custom `UIKit` `UIPopoverPresentationController` — rejected; adds UIKit bridge complexity with no benefit when ZStack achieves the same result.

---

## 2. Menu Animation

**Decision**: Use `Animation.bmFade` (250 ms ease-in-out) for the overlay scrim, and a combined scale-from-top-right + opacity transition for the menu panel itself, anchored at `UnitPoint.topTrailing`.

**Rationale**: `Animation.bmSpring` is ~350 ms and slightly exceeds the 300 ms feedback target in Constitution Principle V. The fade/scale animation at 250 ms satisfies the constitution while still feeling tactile. The `scaleEffect(open ? 1 : 0.92, anchor: .topTrailing).opacity(open ? 1 : 0)` pattern needs no custom ViewModifier — pure SwiftUI.

**Alternatives considered**:
- `bmSpring` — rejected for the menu panel; slightly over 300 ms limit.
- `matchedGeometryEffect` — overkill; no shared geometry between trigger and menu.

---

## 3. New Plan Wizard Presentation

**Decision**: Present `NewPlanWizardView` via `.fullScreenCover(isPresented:)` from `TodayView`.

**Rationale**: The wizard is a modal flow that conceptually replaces the current screen during creation. A full-screen cover prevents the user from accidentally swiping back mid-wizard (losing progress), and matches how `CheckInView` → `ActiveSessionView` is a forward-only push. The wizard has its own internal navigation (step rail) so it does not need to sit inside `TodayView`'s `NavigationStack` path.

**Alternatives considered**:
- `NavigationStack` push from `TodayView` path — rejected; wizard is a separate creation flow, not a drill-down into today's content.
- `.sheet` — rejected; swipe-to-dismiss too easy to trigger accidentally mid-wizard.

---

## 4. Wizard State Machine

**Decision**: `NewPlanViewModel` is a single `@Observable` class that owns the full multi-step state. It holds `selectedDays`, a `dayPlans` dictionary keyed by `DayOfWeek`, and a `currentStep` integer.

**Rationale**: The HTML prototype's state maps directly onto a flat observable model. SwiftUI `@Observable` (iOS 17+) avoids `@StateObject` boilerplate. Keeping all wizard state in one model makes unit testing straightforward — no child ViewModels needed for this feature.

**Alternatives considered**:
- One ViewModel per step — rejected; over-engineering for 3 step types.
- `@StateObject` + `ObservableObject` — rejected; project is iOS 17+ where `@Observable` is preferred.

---

## 5. Exercise Catalog Storage

**Decision**: Hardcode the 18-exercise catalog as a static constant array in `NewPlanModels.swift`. No persistence or backend fetch.

**Rationale**: The HTML prototype defines a fixed set of 18 exercises. For this iteration the catalog is static; a future feature will make it dynamic/user-extensible. Hardcoding avoids any network dependency and keeps the wizard offline-capable.

**Alternatives considered**:
- JSON file in bundle — adds file I/O with no benefit at this scale.
- Backend fetch — out of scope; would require a new API endpoint.

---

## 6. Workout Plan Persistence

**Decision**: On wizard completion, serialize the `WorkoutPlan` to `UserDefaults` using `Codable`. Use a `WorkoutPlanStore` (modelled after the existing `ProfileStore`).

**Rationale**: The project already uses `UserDefaults` via `ProfileStore` for non-sensitive cached data. A `WorkoutPlan` contains no sensitive information (just exercise names and reps targets), so `UserDefaults`/`Codable` is appropriate and avoids the complexity of CoreData for a first-pass persistence layer.

**Alternatives considered**:
- CoreData — rejected; constitution says "CoreData or SwiftData" for local store; acceptable future migration path but not needed now.
- Keychain — rejected; not for non-sensitive data.
- In-memory only (no persistence) — rejected; user would lose their plan on app restart.

---

## 7. Grayscale / WorkoutPalette Boundary

**Decision**: The menu overlay and the wizard are both treated as part of the "workout flow" and may use `WorkoutPalette.accent`, `.accentSoft`, and `.accentInk` for primary CTAs and the "New Workout Plan" icon cell. All structural colors (backgrounds, surfaces, text, dividers) use `GrayscalePalette`.

**Rationale**: `WorkoutPalette.swift` explicitly documents its scope as "used exclusively in the workout flow" and "must NOT leak into non-workout screens." `TodayView` (which hosts the menu) and the New Plan wizard (which creates workout plans) are both unambiguously part of the workout flow. This matches the existing `TodayView` pattern exactly.

**Alternatives considered**:
- Pure grayscale for all new UI — considered; would technically satisfy the constitution letter but would create visual inconsistency with the existing `TodayView` design.

---

## All NEEDS CLARIFICATION Items

None — all questions resolved via the research above.
