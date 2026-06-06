# Tasks: Home Refresh After Workout Completion

**Input**: Design documents from `/specs/022-home-refresh-post-workout/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Scope**: 3 source files modified, 2 test files updated. No new files. No protocol changes.

---

## Phase 1: Setup

No new directories, packages, or project files required. All infrastructure exists.

---

## Phase 2: User Story 1 — Home Screen Refreshes After Completing a Workout (Priority: P1) 🎯 MVP

**Goal**: When the user taps "Done" on `WorkoutCompleteView`, `CheckInView` fully dismisses and the home screen reloads.

**Independent Test**: Verify `TodayViewModel.reload()` transitions `loadState` from `.loaded` → `.loading` → `.loaded`; verify `CheckInView.onComplete` calls `dismiss()` instead of `path.removeLast()`.

- [X] T001 [US1] Check `BodyMetricTests/Features/TodayViewModelTests.swift` for a `test_reload_*` test that verifies `loadState` resets to `.idle` then transitions to `.loaded` after `reload()` — add the test if missing, skip if it already exists

- [X] T002 [P] [US1] In `Features/Workout/Views/CheckInView.swift` (line ~205 inside `.navigationDestination(for: StartSessionResponse.self)`): change `onComplete: { path.removeLast() }` to `onComplete: { dismiss() }` — no other changes in this file

- [X] T003 [P] [US1] In `Features/Workout/Views/TodayView.swift`: add `.onChange(of: showCheckIn) { old, new in guard old && !new else { return }; Task { await viewModel.reload(using: homeService) } }` as a modifier on the `NavigationStack` — place it after the existing `.task { }` modifier

**Checkpoint**: `CheckInView` dismisses after workout; `TodayViewModel.reload()` is called; home screen shows loading state then fresh data.

---

## Phase 3: User Story 2 — Home API Request Includes Current Day (Priority: P2)

**Goal**: `GET /api/home` always includes `?currentDayOfWeek=<UPPERCASED_WEEKDAY>` so the server returns the correct day's data.

**Independent Test**: Capture the `URLRequest` from `HomeService.fetchHomeData()` and assert the URL string contains `currentDayOfWeek=` followed by an uppercase English weekday name.

- [X] T004 [US2] In `BodyMetricTests/Services/HomeServiceTests.swift`: add `test_fetchHomeData_urlContainsCurrentDayOfWeek()` — capture the URLRequest via the mock NetworkClient and assert `request.url?.absoluteString.contains("currentDayOfWeek=")` is `true` and the value is one of the 7 uppercase English weekday names

- [X] T005 [US2] In `Services/Home/HomeService.swift`: replace `guard let url = URL(string: Self.baseURL)` with `URLComponents`-based URL construction that appends `URLQueryItem(name: "currentDayOfWeek", value: Self.currentDayOfWeekString())`; add `private static func currentDayOfWeekString() -> String` using `DateFormatter` with format `"EEEE"`, `locale: Locale(identifier: "en_US")`, and `.uppercased()`

**Checkpoint**: All `GET /api/home` calls include `?currentDayOfWeek=<WEEKDAY>` matching the device's current calendar day.

---

## Phase 4: Build Verification

- [X] T006 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED; depends on T001–T005

---

## Dependencies

```
T001 [US1] (TodayViewModel reload test — write first)
    ↓
T002 [P] [US1] (CheckInView dismiss change)   ← parallel
T003 [P] [US1] (TodayView onChange reload)    ← parallel

T004 [US2] (HomeService URL test — write first)
    ↓
T005 [US2] (HomeService URL implementation)

T002, T003, T005 all complete
    ↓
T006 (build)
```

T002 and T003 touch different files — fully parallel after T001.
T004–T005 are independent of T001–T003 and can run in a separate parallel track.

---

## Parallel Execution

```
Track A (US1):  T001 → T002 + T003 (parallel)
Track B (US2):  T004 → T005
Both tracks → T006 (build)
```

---

## Implementation Strategy

### MVP First (US1 Only — 3 tasks)

1. T001: Add/verify reload test in `TodayViewModelTests.swift`
2. T002: Change `onComplete` in `CheckInView.swift`
3. T003: Add `.onChange` to `TodayView.swift`
4. Run build → validate dismiss + reload end-to-end

### Full Feature

5. T004: Add URL query param test in `HomeServiceTests.swift`
6. T005: Update `HomeService.swift` to append `currentDayOfWeek`
7. T006: Build verification

---

## Notes

- T001: Check first — `TodayViewModelTests` may already have a `test_reload_*` case. Inspect the file before writing; only add if missing.
- T002: One-word change — `path.removeLast()` → `dismiss()`. The `@Environment(\.dismiss)` property already exists in `CheckInView`.
- T003: The `homeService` parameter is already available in `TodayView` as a `let` property. No new injection needed.
- T005: `URLComponents(string:)!` is safe here because `Self.baseURL` is a hardcoded literal. Use `guard let url = components.url` for the final URL to keep error propagation clean.
- T006: Build depends on T002 and T003 being compiled changes; T005 must also compile correctly.
