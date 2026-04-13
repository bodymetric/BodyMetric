# Tasks: Authenticated Area Global Header

**Input**: Design documents from `/specs/003-authenticated-header/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅

**Organization**: Tasks grouped by user story for independent implementation.
**Tests**: Included per constitution Principle II (TDD, ≥ 90% coverage).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to

## Path Conventions

All source paths are relative to:
`/Users/eduardorodrigues/Projects/bodymetric/BodyMetric/`

---

## Phase 1: Setup

**Purpose**: Create directory structure for the shared header module.

- [x] T001 Create directory `Features/Shared/Header/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core ViewModel that both user stories depend on.

- [x] T002 Write `AppHeaderViewModelTests` with cases: `logout()` calls `authService.signOut()`, logout success sets `isAuthenticated = false`, logout failure logs error and does NOT change auth state — in `BodyMetricTests/Features/AppHeaderViewModelTests.swift`
- [x] T003 Implement `AppHeaderViewModel` (`@Observable @MainActor`; holds reference to `AuthServiceProtocol`; `logout()` async calls `authService.signOut()`, catches error and logs via `Logger.error`; fires trace stub `header_logout_tapped`) — in `Features/Shared/Header/AppHeaderViewModel.swift`

**Checkpoint**: ViewModel exists and tests pass. View work can now begin.

---

## Phase 3: User Story 1 — Persistent Header on All Authenticated Screens (Priority: P1) 🎯 MVP

**Goal**: Every authenticated screen shows a header with `AppLogo` on the left
(10 pt leading padding) and a logout icon on the right (10 pt trailing padding)
on a near-black `GrayscalePalette.primary` background.

**Independent Test**: Sign in → home screen shows header → navigate to
CreateUserView → header still present and identical.

### Implementation for User Story 1

- [x] T004 [US1] Implement `AppHeader` view (`HStack` with `GrayscalePalette.primary` background; `Image("AppLogo")` 32×32 pt on left with `.padding(.leading, 10)`; `Button` with `Image(systemName: "rectangle.portrait.and.arrow.right")` SF Symbol on right with `.padding(.trailing, 10)`; calls `viewModel.logout()` on tap; all foreground in `GrayscalePalette.background`) — in `Features/Shared/Header/AppHeader.swift`
- [x] T005 [US1] Update `BodyMetricApp` authenticated container: replace `HomeView(viewModel: makeHomeViewModel())` with a `VStack(spacing: 0)` containing `AppHeader(viewModel: AppHeaderViewModel(authService: authService))` at top + `HomeView(viewModel: makeHomeViewModel())` below, so header appears on every authenticated screen — in `App/BodyMetricApp.swift`

**Checkpoint**: Header visible on home screen after sign-in. Logout button signs out and returns to login screen.

---

## Phase 4: User Story 2 — Header Logo Matches Splash Screen Brand (Priority: P2)

**Goal**: Confirm the logo asset in the header is identical to the splash screen
logo, correctly scaled to 32×32 pt within the header.

**Independent Test**: Visually compare header logo to splash screen logo — same
`AppLogo` asset, no distortion, fits within header height.

### Implementation for User Story 2

- [x] T006 [US2] Verify `AppHeader` uses `Image("AppLogo").resizable().scaledToFit().frame(width: 32, height: 32)` (same asset as `SplashView`) and the image is not clipped or distorted at any Dynamic Type size — review `Features/Shared/Header/AppHeader.swift`

**Checkpoint**: Logo in header matches splash screen logo. No distortion at any text size.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [x] T007 [P] Audit `AppHeader` and `AppHeaderViewModel` for grayscale compliance: confirm no hardcoded `Color` values; all colors use `GrayscalePalette` tokens — `Features/Shared/Header/AppHeader.swift`, `Features/Shared/Header/AppHeaderViewModel.swift`
- [x] T008 [P] Confirm `AppHeader` is injected at the `BodyMetricApp` level so future authenticated screens (e.g. any screen added after `HomeView`) automatically inherit the header without additional wiring — verify `App/BodyMetricApp.swift`

---

## Dependencies & Execution Order

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — T002 before T003 (TDD: test must fail first)
- **Phase 3 (US1)**: Depends on Phase 2 — T004 before T005 (view before wiring)
- **Phase 4 (US2)**: Depends on T004 existing
- **Phase 5 (Polish)**: Depends on Phases 3–4 complete

### Within Phase 2

- T002 (test) MUST be written and FAIL before T003 (implementation)

### Parallel Opportunities

- Phase 5: T007 + T008 can run in parallel

---

## Parallel Example: User Story 1

```text
# Sequential within US1:
T004: AppHeader view (must exist before wiring)
T005: BodyMetricApp wiring (depends on T004)
```

---

## Implementation Strategy

### MVP (User Story 1 only)

1. Phase 1: Create directory
2. Phase 2: Write failing test → implement AppHeaderViewModel
3. Phase 3: Implement AppHeader → wire into BodyMetricApp
4. **STOP and VALIDATE**: Sign in → header visible → logout works ✅

### Incremental Delivery

1. Phase 1–3 → header live on all authenticated screens (MVP)
2. Phase 4 → brand logo verified
3. Phase 5 → compliance audit

---

## Notes

- [P] tasks = different files, no dependencies
- Tests (T002) MUST fail before T003 implementation begins
- Commit after each task using Gitmoji prefix (constitution v3.1.0)
  e.g. `✨ T004: implement AppHeader view`
- The `AppHeaderViewModel` receives `AuthServiceProtocol` — same instance
  already held by `BodyMetricApp` — no new service instantiation needed
