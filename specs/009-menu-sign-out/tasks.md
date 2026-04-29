# Tasks: Home Menu — Sign Out ("Exit")

**Input**: Design documents from `/specs/009-menu-sign-out/`  
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ quickstart.md ✅

**Tests**: Included — required by Constitution Principle II (TDD). Tests for `HomeMenuModels` updates must fail before implementation.

**Organization**: Tasks grouped by user story. 4 modified files, 0 new files.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no shared dependencies)
- **[Story]**: US1 / US2

---

## Phase 1: Setup

No new directories or files required. Skip to Foundational phase.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Extend `HomeMenuItem` with the two new fields and append the "exit" catalog entry. Both user stories depend on the updated model compiling before any view changes can start.

### Tests (write first — must FAIL before T002)

- [x] T001 Update `BodyMetricTests/Features/HomeMenuModelsTests.swift`: change `test_catalog_containsExactlySevenItems` assertion from `7` to `8`; change `test_catalog_exactlyTwoItemsAreActive` assertion from `2` to `3`; add `test_catalog_exitItemIsLast` — `catalog.last?.id == "exit"`; add `test_catalog_exitItemIsSignOut` — `catalog.last?.isSignOut == true`; add `test_catalog_exitItemHasSeparator` — `catalog.last?.isSeparatorAbove == true`; add `test_catalog_exitItemHasNilDestination` — `catalog.last?.destination == nil`; add `test_catalog_exitItemIsActive` — `catalog.last?.isActive == true`

### Implementation

- [x] T002 Modify `Features/Workout/Models/HomeMenuModels.swift`: add `let isSignOut: Bool` with default `false` and `let isSeparatorAbove: Bool` with default `false` to `HomeMenuItem`; add all existing catalog entries' new parameters as `isSignOut: false, isSeparatorAbove: false` (or rely on default args if the struct uses default param values — verify which approach compiles correctly); append as the 8th catalog entry: `HomeMenuItem(id: "exit", label: "Exit", subtitle: "Sign out of your account", iconName: "rectangle.portrait.and.arrow.right", isActive: true, isPrimary: false, destination: nil, isSignOut: true, isSeparatorAbove: true)`; run T001 — all 7 tests must pass

**Checkpoint**: Model compiles; T001 passes. View wiring can now begin.

---

## Phase 3: User Story 1 — Sign out from the home menu (Priority: P1) 🎯 MVP

**Goal**: User taps "Exit" in the home menu → app signs out → login screen appears. Menu closes immediately; sign-out runs async in the background.

**Independent Test**: Open home menu while authenticated → tap "Exit" → verify login screen appears and reopening the app shows login screen (no session restored).

### Implementation for US1

- [x] T003 [P] [US1] Modify `Features/Workout/Views/Components/HomeMenuView.swift`: add `var onSignOut: (() -> Void)? = nil` parameter to the struct; in `menuItemRow(_:)`, before the `Button { ... } label: { ... }` call, add: `if item.isSeparatorAbove { Divider().background(GrayscalePalette.separator).padding(.horizontal, 6).padding(.vertical, 2) }`; change the Button action to: `if item.isSignOut { Logger.info("menu_sign_out_tapped"); isPresented = false; onSignOut?() } else { guard item.isActive else { return }; Logger.info("menu_item_tapped destination:\(item.id)"); onNavigate(item.destination ?? .today) }`; for the exit row's icon cell, use `GrayscalePalette.secondary` fill (not `background`) and set icon foreground to `GrayscalePalette.secondary`; for the exit row's label `Text`, use `.foregroundStyle(GrayscalePalette.secondary)` instead of `.foregroundStyle(GrayscalePalette.primary)`
- [x] T004 [P] [US1] Modify `Features/Workout/Views/TodayView.swift`: add `let onSignOut: @escaping () -> Void` as a new parameter; in `body`, update `HomeMenuView(...)` call to include `onSignOut: onSignOut`; update the `#Preview` stub at the bottom to pass `onSignOut: {}`
- [x] T005 [US1] Modify `Features/Navigation/MainTabView.swift`: in `TabContent(selectedTab:homeViewModel:)`, update the `TodayView(...)` call to include `onSignOut: { [authService] in Task { try? await authService.signOut() } }`; this requires that `MainTabView` captures `authService` in the closure — confirm `authService` is accessible in the `TabContent` scope (it is a `let` property on `MainTabView`); depends on T004

**Checkpoint**: User Story 1 fully functional. Tap "Exit" → menu closes → `AuthService.signOut()` fires → `isAuthenticated = false` → `BodyMetricApp` routes to `LoginView`.

---

## Phase 4: User Story 2 — Sign-out is non-destructive to user data (Priority: P2)

**Goal**: After signing out and signing back in, all user data (workout plans, profile) is still accessible. No data is deleted by the sign-out action.

**Independent Test**: Sign out via "Exit", sign back in, verify all previously accessible data is present.

### Implementation for US2

- [x] T006 [US2] Verify `Services/Auth/AuthService.swift` `signOut()` method does NOT clear `ProfileStore` data (it should only clear tokens); inspect the method — if it calls `profileStore.clear()`, remove that call; add a single-line comment on the `signOut()` method confirming: `// ProfileStore data is intentionally preserved — only tokens are cleared on sign-out`; this is a verification/documentation task; no functional code change expected

**Checkpoint**: Both user stories independently functional and verified.

---

## Final Phase: Polish & Cross-Cutting Concerns

- [x] T007 [P] Audit Constitution VI compliance in modified files: run `grep -n "Color(" Features/Workout/Models/HomeMenuModels.swift Features/Workout/Views/Components/HomeMenuView.swift Features/Workout/Views/TodayView.swift Features/Navigation/MainTabView.swift` — confirm zero raw `Color(red:green:blue:)` values; all colors must reference `GrayscalePalette.*` or `WorkoutPalette.*` tokens
- [x] T008 [P] Audit trace event: confirm `Logger.info("menu_sign_out_tapped")` is present in `Features/Workout/Views/Components/HomeMenuView.swift` exit-item tap handler (Constitution Principle IV)
- [x] T009 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED with no new errors

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 2 (Foundational)**: T001 (tests) → T002 (impl) — blocking all story phases
- **Phase 3 (US1)**: T003 and T004 are parallel (different files); T005 depends on T004
- **Phase 4 (US2)**: T006 is independent — can run in parallel with Phase 3
- **Final Phase**: T007, T008, T009 all run after Phase 3+4 complete; T007 and T008 are parallel

### Within Phase 3

| Task | Depends on |
|------|-----------|
| T003 (`HomeMenuView`) | T002 (HomeMenuItem.isSignOut field must exist) |
| T004 (`TodayView`) | T003 (HomeMenuView must have onSignOut param) |
| T005 (`MainTabView`) | T004 (TodayView must have onSignOut param) |

T003 and T004 can be written simultaneously (T004 doesn't need T003 to compile — it just needs the view to accept the parameter).

---

## Parallel Opportunities

```
Phase 2:
  T001 (write tests, verify FAIL) → T002 (implement, run tests to PASS)

Phase 3 + 4 (after T002):
  Parallel:  T003 (HomeMenuView)  |  T004 (TodayView)  |  T006 (US2 verification)
  Then:      T005 (MainTabView)  [needs T004]

Final (after all story phases):
  Parallel:  T007 (palette audit)  |  T008 (trace audit)
  Then:      T009 (build)
```

---

## Implementation Strategy

### MVP (User Story 1 only — 6 tasks)

1. Phase 2: T001 → T002 (model update)
2. Phase 3: T003 + T004 (parallel) → T005
3. **STOP**: Verify — open menu, tap "Exit", confirm login screen appears
4. Final: T007 + T008 + T009

### Full Delivery (all stories — 9 tasks)

Same as above + T006 (US2 verification) in parallel with Phase 3.

---

## Notes

- `[P]` tasks touch different files — safe to run in parallel
- Constitution II requires TDD: T001 tests MUST fail before T002 is started
- `AuthService.signOut()` is already tested in `BodyMetricTests/Services/AuthServiceTests.swift` — no new service tests needed
- No new SPM packages, no new files, no new Xcode target registration required
- Commit convention: `💄 T003: add Exit row styling to HomeMenuView`
