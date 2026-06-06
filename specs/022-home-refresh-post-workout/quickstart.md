# Quickstart: Home Refresh After Workout Completion

**Branch**: `022-home-refresh-post-workout` | **Date**: 2026-05-31

## Integration Scenarios

---

### Scenario 1 — Correct URL with currentDayOfWeek query parameter

**Setup**: Call `HomeService.fetchHomeData()` on any weekday. Capture the outgoing `URLRequest`.

**Expected**: Request URL contains `?currentDayOfWeek=<UPPERCASED_WEEKDAY>` matching the device's current calendar day (e.g., `?currentDayOfWeek=MONDAY` on a Monday).

---

### Scenario 2 — Workout completion dismisses CheckInView and triggers home reload

**Setup**: `TodayView` with `showCheckIn = true`. Simulate `onComplete` firing (the callback passed to `ActiveSessionView`).

**Expected**:
- `showCheckIn` becomes `false` (CheckInView dismissed)
- `TodayViewModel.loadState` transitions through `.loading` → `.loaded`

---

### Scenario 3 — Home reload succeeds after workout

**Setup**: `MockHomeService` returns fresh `HomeScreenData` on the second call.

**Expected**: After reload completes, `viewModel.loadState == .loaded(freshData)`.

---

### Scenario 4 — Home reload fails after workout

**Setup**: `MockHomeService` throws `WorkoutPlanError.serverError(500)` on reload.

**Expected**:
- `viewModel.loadState == .failed("Could not load home data. Please try again.")`
- Error banner with retry button visible in `TodayView`

---

### Scenario 5 — Guard against double-fire

**Setup**: `viewModel.loadState = .loading`. Call `viewModel.loadHomeData(using:)` again.

**Expected**: Second call returns immediately without firing a network request (existing guard: `guard loadState != .loading`).

---

### Scenario 6 — Build passes with zero errors

`xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` exits `BUILD SUCCEEDED`.
