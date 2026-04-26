# Tasks: Splash Screen Bouncing Logo

**Input**: User request — "Make a logo in splash screen bouncing"
**Scope**: Single-file UI animation change to `Features/Splash/SplashView.swift`

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: User Story 1 — Bouncing Logo Animation (Priority: P1) 🎯

**Goal**: The app logo bounces continuously on the splash screen while the
app resolves auth state, providing visual feedback that the app is loading.

**Independent Test**: Launch app → splash screen → logo visibly bounces
up and down with a smooth spring animation.

### Implementation

- [ ] T001 [US1] Add `@State private var bouncing` and `onAppear` trigger to `SplashView`; apply `.offset(y: bouncing ? -20 : 0)` with `Animation.spring(response: 0.5, dampingFraction: 0.4).repeatForever(autoreverses: true)` to the `Image("AppLogo")` in `Features/Splash/SplashView.swift`

**Checkpoint**: Logo bounces immediately on splash screen. No other views affected.

---

## Dependencies & Execution Order

- T001: No dependencies — can implement immediately.

---

## Notes

- [P] tasks = different files, no dependencies
- Commit with Gitmoji prefix per constitution v3.1.0 (e.g. `💄 T001: add bouncing logo animation to splash screen`)
