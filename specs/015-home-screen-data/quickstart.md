# Quickstart: Home Screen Live Data

**Date**: 2026-05-03

---

## New files

| File | Purpose |
|------|---------|
| `Models/HomeModels.swift` | `HomeScreenData`, `WorkoutDayPlanSummary`, `TodayExercise` |
| `Services/Home/HomeServiceProtocol.swift` | `fetchHomeData()` contract |
| `Services/Home/HomeService.swift` | `GET /api/home` implementation |
| `Features/Workout/ViewModels/TodayViewModel.swift` | Load state machine + derived properties |

---

## HomeServiceProtocol

```swift
@MainActor
protocol HomeServiceProtocol: AnyObject {
    func fetchHomeData() async throws -> HomeScreenData
}
```

---

## TodayViewModel

```swift
@Observable @MainActor
final class TodayViewModel {
    var loadState: HomeLoadState = .idle

    var hasActivePlan: Bool {
        guard case .loaded(let d) = loadState else { return false }
        return d.currentWorkoutDayPlan != nil
    }

    var workoutPlan: WorkoutDayPlanSummary? {
        guard case .loaded(let d) = loadState else { return nil }
        return d.currentWorkoutDayPlan
    }

    var exercisesForToday: [TodayExercise] {
        guard case .loaded(let d) = loadState else { return [] }
        return d.exercisesForToday ?? []
    }

    func loadHomeData(using service: any HomeServiceProtocol) async {
        guard loadState != .loading else { return }
        loadState = .loading
        Logger.info("home_data_load_started")
        do {
            let data = try await service.fetchHomeData()
            loadState = .loaded(data)
            Logger.info("home_data_load_success hasActivePlan:\(hasActivePlan)")
        } catch {
            Logger.error("home_data_load_failed", error: error)
            loadState = .failed("Could not load home data. Please try again.")
        }
    }

    func reload(using service: any HomeServiceProtocol) async {
        loadState = .idle
        await loadHomeData(using: service)
    }
}
```

---

## TodayView signature change

```swift
// BEFORE
struct TodayView: View {
    let workout: WorkoutSession
    let streak: WorkoutStreak
    let userName: String
    let networkClient: any NetworkClientProtocol
    let onSignOut: @MainActor () -> Void
    ...
}

// AFTER
struct TodayView: View {
    let viewModel: TodayViewModel
    let userName: String
    let networkClient: any NetworkClientProtocol
    let onSignOut: @MainActor () -> Void
    let homeService: any HomeServiceProtocol
    ...
    // In body, .task { await viewModel.loadHomeData(using: homeService) }
}
```

---

## HomeMenuView change

```swift
// Add parameter:
var hasActivePlan: Bool = false

// In menuItemRow, override isActive for specific items:
private func effectiveIsActive(for item: HomeMenuItem) -> Bool {
    switch item.id {
    case "newPlan": return !hasActivePlan
    case "myPlans": return hasActivePlan
    default: return item.isActive
    }
}
```

---

## MainTabView change

```swift
// Add parameters:
let homeService: any HomeServiceProtocol
// In TabContent:
TodayView(
    viewModel: TodayViewModel(),  // or injected
    userName: profileStore.name ?? "You",
    networkClient: networkClient,
    onSignOut: { ... },
    homeService: homeService
)
```

---

## BodyMetricApp change

```swift
// Create HomeService alongside other services:
let homeService = HomeService(networkClient: client)
// Pass to MainTabView
```

---

## Skeleton implementation

While `loadState == .loading`, replace workout hero card and exercise section with shimmer-style `RoundedRectangle` placeholders:

```swift
private var skeletonCard: some View {
    RoundedRectangle(cornerRadius: 28, style: .continuous)
        .fill(GrayscalePalette.surface)
        .frame(height: 200)
        .shimmer()  // or just use opacity animation
}
```

---

## Trace events

| Event | When |
|-------|------|
| `home_data_load_started` | `loadHomeData` begins |
| `home_data_load_success` | 200 decoded successfully |
| `home_data_load_failed` | Any error |
