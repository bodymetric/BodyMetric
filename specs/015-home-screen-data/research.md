# Research: Home Screen Live Data

**Date**: 2026-05-03

---

## 1. TodayViewModel owns load state; TodayView is purely declarative

**Decision**: Introduce `TodayViewModel` (`@Observable @MainActor`) that owns `loadState: HomeLoadState`, `hasActivePlan: Bool` (derived), and calls `loadHomeData(using:)`. `TodayView` observes the ViewModel and renders declaratively.

**Rationale**: Matches the project's established `@Observable` ViewModel pattern (e.g., `HomeViewModel`, `NewPlanViewModel`). Keeps the view thin and testable.

---

## 2. HomeLoadState enum

```swift
enum HomeLoadState: Equatable {
    case idle
    case loading
    case loaded(HomeScreenData)
    case failed(String)
}
```

---

## 3. TodayView parameters change

**Before**: `let workout: WorkoutSession`, `let streak: WorkoutStreak` (mock data)  
**After**: `let viewModel: TodayViewModel` (live data via ViewModel)  
`userName`, `networkClient`, `onSignOut` remain.

The streak ribbon stays as mock for this feature; it is not part of the `GET /api/home` response.

---

## 4. Menu dynamic state via hasActivePlan

**Decision**: `HomeMenuView` gains `var hasActivePlan: Bool = false`. When rendering items, the view overrides the static `isActive` for "New Workout Plan" and "My Plans":

- "New Workout Plan": `isActive = !hasActivePlan`
- "My Plans": `isActive = hasActivePlan`

The static catalog remains unchanged; only the rendering is dynamic.

---

## 5. Skeleton implementation

**Decision**: Use shimmer-like placeholder `RoundedRectangle` fills in GrayscalePalette.surface while `loadState == .loading`. These replace the workout hero card and exercise section.

---

## 6. exercisesForToday — minimum fields assumed

**Decision**: `TodayExercise: Decodable, Identifiable` with `let id: Int` and `let name: String`. Additional fields may be present and are silently ignored.

---

## 7. HomeService injection chain

`BodyMetricApp` creates `HomeService(networkClient: networkClient)` → passes to `MainTabView` → `MainTabView` creates `TodayViewModel(homeService: homeService)` → passes to `TodayView`.

**Alternatively**: `TodayViewModel` can accept `networkClient` and create `HomeService` internally (simpler injection). Decision: inject `HomeServiceProtocol` into `TodayViewModel` for testability.

---

## All NEEDS CLARIFICATION Items

None — all decisions resolved.
