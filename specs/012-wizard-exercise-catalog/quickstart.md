# Quickstart: Wizard Step 2 — Live Exercise Catalog

**Date**: 2026-05-01

---

## New files

| File | Purpose |
|------|---------|
| `Models/ExerciseCatalogModels.swift` | `ApiExercise`, `ExerciseCatalogGroup` DTOs |
| `Services/Exercise/ExerciseServiceProtocol.swift` | `fetchExerciseCatalog()` contract |
| `Services/Exercise/ExerciseService.swift` | `GET /api/exercises` implementation |
| `BodyMetricTests/Services/ExerciseServiceTests.swift` | Unit tests |

---

## ExerciseServiceProtocol

```swift
@MainActor
protocol ExerciseServiceProtocol: AnyObject {
    func fetchExerciseCatalog() async throws -> [ExerciseCatalogGroup]
}
```

---

## NewPlanViewModel additions

```swift
var exerciseGroups: [ExerciseCatalogGroup] = []
var exerciseCatalogLoadState: ExerciseCatalogLoadState = .idle

func loadExerciseCatalog(using service: any ExerciseServiceProtocol) async {
    guard exerciseGroups.isEmpty else { return }  // single-load guard
    exerciseCatalogLoadState = .loading
    Logger.info("exercise_catalog_load_started")
    do {
        exerciseGroups = try await service.fetchExerciseCatalog()
        exerciseCatalogLoadState = .loaded
        Logger.info("exercise_catalog_load_success groupCount:\(exerciseGroups.count)")
    } catch {
        Logger.error("exercise_catalog_load_failed", error: error)
        exerciseCatalogLoadState = .failed("Could not load exercises. Please try again.")
    }
}

func reloadExerciseCatalog(using service: any ExerciseServiceProtocol) async {
    exerciseGroups = []  // clear to force re-fetch
    await loadExerciseCatalog(using: service)
}

func exerciseName(for exerciseId: String) -> String? {
    guard let id = Int(exerciseId) else { return nil }
    return exerciseGroups.flatMap(\.exercises).first { $0.id == id }?.name
}
```

---

## ConfigureDayStepView wiring

```swift
struct ConfigureDayStepView: View {
    @Bindable var viewModel: NewPlanViewModel
    let day: DayOfWeek
    let dayIndex: Int
    let totalDays: Int
    let exerciseService: any ExerciseServiceProtocol   // NEW

    var body: some View {
        VStack { ... }
        .task {
            await viewModel.loadExerciseCatalog(using: exerciseService)
        }
    }
}
```

Error/loading states in body (above `blockSection`):
```swift
// Loading state
if viewModel.exerciseCatalogLoadState == .loading {
    exerciseCatalogLoadingView
}
// Error state  
if case .failed(let msg) = viewModel.exerciseCatalogLoadState {
    exerciseCatalogErrorBanner(msg, retryAction: {
        Task { await viewModel.reloadExerciseCatalog(using: exerciseService) }
    })
}
```

---

## ExercisePickerSheetView changes

```swift
// Add parameter:
let exerciseCatalog: [ExerciseCatalogGroup]

// Replace filteredGroups computed var:
private var filteredGroups: [ExerciseCatalogGroup] {
    let trimmed = query.trimmingCharacters(in: .whitespaces).lowercased()
    guard !trimmed.isEmpty else { return exerciseCatalog }
    return exerciseCatalog.compactMap { group in
        let filtered = group.exercises.filter {
            $0.name.lowercased().contains(trimmed) ||
            group.group.lowercased().contains(trimmed)
        }
        return filtered.isEmpty ? nil :
            ExerciseCatalogGroup(group: group.group, exercises: filtered)
    }
}

// Update exercise row to use Int id and pass String to onPick:
Button { onPick(String(ex.id)); dismiss() } label: { ... }
```

---

## ExerciseBlockRowView changes

```swift
// Add parameter:
let exerciseName: String?

// Remove:
// private var selectedExercise: Exercise? { Exercise.catalog.first { ... } }

// Update picker trigger label to use exerciseName directly
```

In `ConfigureDayStepView`, pass:
```swift
ExerciseBlockRowView(
    ...,
    exerciseName: viewModel.exerciseName(for: block.exerciseId),
    ...
)
```

---

## NewPlanWizardView

```swift
struct NewPlanWizardView: View {
    let service: any WorkoutPlanServiceProtocol
    let dayConfigService: any WorkoutDayPlanServiceProtocol
    let exerciseService: any ExerciseServiceProtocol   // NEW
    ...
    // In stepBody, pass exerciseService to ConfigureDayStepView:
    ConfigureDayStepView(
        viewModel: viewModel,
        day: day,
        dayIndex: ...,
        totalDays: ...,
        exerciseService: exerciseService   // NEW
    )
}
```

---

## TodayView

```swift
.fullScreenCover(isPresented: $showWizard) {
    NewPlanWizardView(
        service: WorkoutPlanService(networkClient: networkClient),
        dayConfigService: WorkoutDayPlanService(networkClient: networkClient),
        exerciseService: ExerciseService(networkClient: networkClient)   // NEW
    )
}
```

---

## Trace events

| Event | When |
|-------|------|
| `exercise_catalog_load_started` | `loadExerciseCatalog` begins |
| `exercise_catalog_load_success` | 200 response decoded |
| `exercise_catalog_load_failed` | Any error |
