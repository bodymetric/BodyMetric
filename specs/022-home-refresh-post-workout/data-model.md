# Data Model: Home Refresh After Workout Completion

**Branch**: `022-home-refresh-post-workout` | **Date**: 2026-05-31

## Entities (all existing — no new types)

### TodayViewModel

Key state property driving the home screen:

| Property | Type | Transition |
|----------|------|------------|
| `loadState` | `HomeLoadState` | `loaded(stale)` → `loading` → `loaded(fresh)` after workout complete |

`HomeLoadState` enum (existing):
```swift
enum HomeLoadState: Equatable {
    case idle
    case loading
    case loaded(HomeScreenData)
    case failed(String)
}
```

### HomeScreenData (existing, no change)

Decoded from `GET /api/home?currentDayOfWeek=<WEEKDAY>`.

| Field | Type | Notes |
|-------|------|-------|
| currentWorkoutDayPlan | WorkoutDayPlanSummary? | Today's workout summary (nil if none) |
| exercisesForToday | [TodayExercise]? | Ordered exercise list for today |

### HomeService (modified — query parameter added)

| Aspect | Before | After |
|--------|--------|-------|
| Request URL | `https://api.bodymetric.com.br/api/home` | `https://api.bodymetric.com.br/api/home?currentDayOfWeek=MONDAY` |
| Protocol signature | `fetchHomeData() async throws -> HomeScreenData` | unchanged |
| Day computation | N/A | `DateFormatter("EEEE", en_US).string(from: Date()).uppercased()` |

## State Transitions

```
TodayView lifecycle on workout completion:
  showCheckIn = true   (user taps "Start Workout")
      ↓
  [workout in progress — CheckInView active]
      ↓
  user taps "Done" on WorkoutCompleteView
      ↓
  CheckInView.dismiss() → showCheckIn = false
      ↓
  TodayView.onChange(of: showCheckIn) fires
      ↓
  viewModel.reload(using: homeService)
      ↓
  loadState: .loaded(stale) → .idle → .loading → .loaded(fresh) | .failed(msg)
```

## Source Model Mapping

```
Date() → DateFormatter("EEEE", en_US).uppercased() → currentDayOfWeek query param
TodayViewModel.reload()          → HomeService.fetchHomeData()
                                 → GET /api/home?currentDayOfWeek=<WEEKDAY>
                                 → HomeScreenData decoded
                                 → TodayViewModel.loadState = .loaded(data)
```
