# Quickstart: Home Menu Dropdown

**Feature**: `006-home-menu-dropdown`  
**Date**: 2026-04-25

## What This Feature Adds

1. **`HomeMenuView`** — a dropdown overlay panel triggered by the mascot chip on `TodayView`, with 7 navigation items.
2. **`NewPlanWizardView`** — a multi-step full-screen wizard for creating a weekly workout plan.
3. **`WorkoutPlanStore`** — a `UserDefaults`-backed store that persists the resulting `WorkoutPlan`.

---

## Key Components

### HomeMenuView

**File**: `Features/Workout/Views/Components/HomeMenuView.swift`

- Rendered as a ZStack overlay inside `TodayView`
- Controlled by `@Binding var isPresented: Bool` and `@Binding var currentDestination: HomeMenuDestination?`
- Animates in with `.bmFade` + `scaleEffect(anchor: .topTrailing)`
- Scrim tap sets `isPresented = false`
- Item taps: set `currentDestination` + set `isPresented = false`

**Trigger in TodayView**:
```swift
// In TodayView:
@State private var menuOpen = false
@State private var menuDestination: HomeMenuDestination?

// Mascot chip becomes a Button:
Button { menuOpen = true } label: { MascotChip() }

// Overlay:
.overlay {
    HomeMenuView(isPresented: $menuOpen,
                 destination: $menuDestination,
                 userName: userName)
}

// Navigate on destination change:
.fullScreenCover(item: $menuDestination) { dest in
    if dest == .newWorkoutPlan {
        NewPlanWizardView()
    }
}
```

---

### NewPlanWizardView

**File**: `Features/NewPlan/Views/NewPlanWizardView.swift`

- Root view; owns `@State private var viewModel = NewPlanViewModel()`
- Routes to the correct step view based on `viewModel.currentStep`
- Has sticky header (step indicator + back) and sticky footer (Continue/Finish CTA)

**Step routing**:
```swift
// Step 1
SelectDaysStepView(viewModel: viewModel)

// Steps 2…N (one per selected day)
ConfigureDayStepView(viewModel: viewModel, dayIndex: viewModel.currentStep - 2)

// Step N+1 (review)
ReviewStepView(viewModel: viewModel)
```

---

### NewPlanViewModel

**File**: `Features/NewPlan/ViewModels/NewPlanViewModel.swift`

```swift
@Observable final class NewPlanViewModel {
    var selectedDays: Set<DayOfWeek> = [.monday, .wednesday, .friday]
    var dayPlans: [DayOfWeek: DayPlan] = [:]
    var currentStep: Int = 1
    var activePickerBlockId: UUID? = nil
    var isPresentingSuccess: Bool = false

    var totalSteps: Int { 2 + orderedSelectedDays.count }
    var orderedSelectedDays: [DayOfWeek] { ... }

    func toggleDay(_ day: DayOfWeek) { ... }
    func advance() { ... }
    func retreat(onCancel: () -> Void) { ... }
    func jumpTo(step: Int) { ... }
    func addBlock(for day: DayOfWeek) { ... }
    func removeBlock(id: UUID, from day: DayOfWeek) { ... }
    func updateBlock(id: UUID, day: DayOfWeek, patch: (inout ExerciseBlock) -> Void) { ... }
    func finish(store: WorkoutPlanStore) { ... }
    func isStepValid(_ step: Int) -> Bool { ... }
}
```

---

### WorkoutPlanStore

**File**: `Features/NewPlan/Models/WorkoutPlanStore.swift`  
_(or `Services/WorkoutPlan/WorkoutPlanStore.swift` — follows existing service layout)_

```swift
@Observable final class WorkoutPlanStore {
    private(set) var currentPlan: WorkoutPlan?
    
    func save(_ plan: WorkoutPlan) { ... }  // writes to UserDefaults
    func load() { ... }                     // reads from UserDefaults
}
```

---

## Interaction Tracing Hooks

All trace calls use `Logger.info` in this iteration (pending `TRACING_BACKEND` decision in Principle IV).

| Event | When | Parameters |
|-------|------|------------|
| `menu_opened` | Mascot chip tapped | — |
| `menu_item_tapped` | Any active item tapped | `destination: String` |
| `menu_dismissed` | Scrim or ✕ tapped | — |
| `wizard_step_advanced` | Continue tapped | `step: Int` |
| `wizard_day_toggled` | Day chip tapped in step 1 | `day: String`, `selected: Bool` |
| `wizard_finished` | Finish & Save tapped | `dayCount: Int`, `blockCount: Int` |
| `wizard_cancelled` | Back tapped on step 1 | — |

---

## Running Tests

```bash
# Unit tests
xcodebuild test -scheme BodyMetric -destination 'platform=iOS Simulator,name=iPhone 16'

# Filter to this feature
xcodebuild test -scheme BodyMetric -destination '...' \
  -only-testing:BodyMetricTests/HomeMenuViewModelTests \
  -only-testing:BodyMetricTests/NewPlanViewModelTests
```

---

## Design Tokens Reference

| Use case | Token |
|----------|-------|
| Backgrounds, text, surfaces, dividers | `GrayscalePalette.*` |
| "New Workout Plan" icon cell background | `WorkoutPalette.accentSoft` |
| "New Workout Plan" icon foreground | `WorkoutPalette.accentInk` |
| "Continue" / "Finish & Save" button fill | `WorkoutPalette.accent` |
| Text on accent CTA | `WorkoutPalette.onAccent` |
| All other menu items | `GrayscalePalette.*` only |

**Rule**: `WorkoutPalette` tokens are confined to `HomeMenuView` and `NewPlan/` views only.

---

## File Checklist

New files to create:

- [ ] `Features/Workout/Views/Components/HomeMenuView.swift`
- [ ] `Features/NewPlan/Models/NewPlanModels.swift`
- [ ] `Features/NewPlan/ViewModels/NewPlanViewModel.swift`
- [ ] `Features/NewPlan/Views/NewPlanWizardView.swift`
- [ ] `Features/NewPlan/Views/Components/WizardStepRailView.swift`
- [ ] `Features/NewPlan/Views/Components/SelectDaysStepView.swift`
- [ ] `Features/NewPlan/Views/Components/ConfigureDayStepView.swift`
- [ ] `Features/NewPlan/Views/Components/ExerciseBlockRowView.swift`
- [ ] `Features/NewPlan/Views/Components/ExercisePickerSheetView.swift`
- [ ] `Features/NewPlan/Views/Components/ReviewStepView.swift`
- [ ] `Features/NewPlan/Views/Components/PlanSavedView.swift`
- [ ] `Features/NewPlan/Models/WorkoutPlanStore.swift`
- [ ] `BodyMetricTests/Features/HomeMenuViewModelTests.swift`
- [ ] `BodyMetricTests/Features/NewPlanViewModelTests.swift`

Files to modify:

- [ ] `Features/Workout/Views/TodayView.swift` — make mascot chip tappable; add overlay + fullScreenCover
