# Research: Authenticated Area Global Header

**Feature**: 003-authenticated-header
**Date**: 2026-04-10

## R1 — Global Header Pattern in SwiftUI

**Decision**: Implement `AppHeader` as a standalone SwiftUI `View` struct
injected at the top of an authenticated container `VStack` inside `BodyMetricApp`.
No `toolbar` or `NavigationStack` toolbar API used.

**Rationale**: `NavigationStack` toolbars are screen-scoped and cannot be
shared globally without repeating the modifier on every view. A single `VStack`
wrapper with `AppHeader` at the top gives guaranteed presence on every
authenticated screen without per-screen wiring.

**Alternative rejected**: `.toolbar { }` modifier — requires adding to every
screen individually; misses future screens if forgotten.

## R2 — Sign-Out Action Ownership

**Decision**: `AppHeaderViewModel` owns the `logout()` async action. It calls
`authService.signOut()` and traces `header_logout_tapped`. `BodyMetricApp`
passes the `AuthService` instance into the view model.

**Rationale**: Keeps the view dumb; ViewModel is unit-testable via
`AuthServiceProtocol` mock. Sign-out error is caught and logged — user stays
authenticated until sign-out succeeds (FR-007).

**Alternative rejected**: Inline `Button` action in `AppHeader` with direct
`authService` call — untestable; breaks separation of concerns.

## R3 — Grayscale Compliance for Header Background

**Decision**: `GrayscalePalette.primary` (near-black `#1A1A1A` in light mode,
`#FFFFFF` in dark mode via adaptive color). Logo rendered with
`.symbolRenderingMode(.monochrome)` for SF Symbol fallback; `AppLogo` image
asset is already grayscale.

**Rationale**: Fully compliant with Constitution Principle VI. Near-black
provides strong visual separation from the content area without using color.

**Alternative rejected**: Dark green background — user chose Option B
(grayscale) during spec review.

## R4 — Header Height & Safe Area

**Decision**: Header uses `.padding(.horizontal, 10)` and `.padding(.vertical, 8)`
inside a `HStack`. Safe area is respected by placing the header inside the
default SwiftUI layout (which already accounts for the status bar/Dynamic Island).
No manual safe-area inset manipulation needed.

**Rationale**: SwiftUI handles safe area automatically for views that don't
use `.ignoresSafeArea()`. The header inherits this behavior for free.

## R5 — Logo in Header

**Decision**: Reuse the `AppLogo` image asset (same as splash screen) at
32×32 pt inside the header. `Image("AppLogo").resizable().scaledToFit().frame(width: 32, height: 32)`.

**Rationale**: Consistent brand identity per US2. 32 pt fits comfortably in
a standard iOS navigation-bar-height-equivalent (~44 pt touch target row).
