# Tasks: Home Screen Live Data

**Input**: Design documents from `/specs/015-home-screen-data/`  
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Tests**: Included — Constitution Principle II (TDD, ≥ 90% coverage). Write tests first; verify FAIL before implementing.

**Organization**: Tasks grouped by user story for independent delivery.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1 / US2 / US3

---

## Phase 1: Setup

**Purpose**: Create new `Services/Home/` directory and register all new placeholder files so subsequent tasks have valid Xcode targets.

- [x] T001 Create directory `Services/Home/` and create placeholder files (each containing only `import Foundation`): `Services/Home/HomeServiceProtocol.swift`, `Services/Home/HomeService.swift`; create `BodyMetricTests/Services/HomeServiceTests.swift` (containing only `import XCTest`) and `BodyMetricTests/Features/TodayViewModelTests.swift` (containing only `import XCTest`); register all four in `BodyMetric.xcodeproj` (first two in BodyMetric target under a new `Services/Home/` group alongside `WorkoutPlan/`; test files in BodyMetricTests target under their respective groups); also register `Models/HomeModels.swift` (placeholder) and `Features/Workout/ViewModels/TodayViewModel.swift` (placeholder) in BodyMetric target

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Data models, service protocol, concrete service, and ViewModel. All user stories depend on these compiling.

### Tests (write first — must FAIL before T006/T007)

- [x] T002 [P] Write failing unit tests in `BodyMetricTests/Services/HomeServiceTests.swift`: `test_fetchHomeData_200_returnsHomeScreenData` — mock JSON `{"currentWorkoutDayPlan":{"name":"Peito","numberOfExercisesTotal":3,"numberSetsTotal":9,"timeEstimateToFinishes":45},"exercisesForToday":[{"id":26,"name":"Bench Press"}]}`, assert plan name is "Peito" and exercises count is 1; `test_fetchHomeData_200_noPlan_returnsNilPlan` — mock JSON `{"exercisesForToday":[]}`, assert `currentWorkoutDayPlan == nil`; `test_fetchHomeData_500_throwsServerError`; `test_fetchHomeData_networkError_throws`

- [x] T003 [P] Write failing unit tests in `BodyMetricTests/Features/TodayViewModelTests.swift`: `test_loadHomeData_success_setsLoadedState` — mock service returns full data, assert `loadState == .loaded(...)`; `test_loadHomeData_success_hasActivePlanTrue` — mock returns plan, assert `hasActivePlan == true`; `test_loadHomeData_noPlan_hasActivePlanFalse` — mock returns nil plan, assert `hasActivePlan == false`; `test_loadHomeData_failure_setsFailedState` — mock throws, assert `loadState == .failed(...)`; `test_loadHomeData_calledWhileLoading_noOpSecondCall`; define `MockHomeService: HomeServiceProtocol`

### Implementation

- [x] T004 [P] Create `Models/HomeModels.swift`: define `struct HomeScreenData: Decodable { let currentWorkoutDayPlan: WorkoutDayPlanSummary?; let exercisesForToday: [TodayExercise]? }`; define `struct WorkoutDayPlanSummary: Decodable { let name: String; let numberOfExercisesTotal: Int; let numberSetsTotal: Int; let timeEstimateToFinishes: Int }`; define `struct TodayExercise: Decodable, Identifiable { let id: Int; let name: String }`; define `enum HomeLoadState: Equatable { case idle; case loading; case loaded(HomeScreenData); case failed(String) }`; make `HomeLoadState.Equatable` work (loaded case requires `HomeScreenData: Equatable` — add `Equatable` conformance to all three structs); register in BodyMetric target; depends on T001

- [x] T005 [P] Populate `Services/Home/HomeServiceProtocol.swift`: define `@MainActor protocol HomeServiceProtocol: AnyObject { func fetchHomeData() async throws -> HomeScreenData }`; register in BodyMetric target; depends on T004

- [x] T006 Populate `Services/Home/HomeService.swift`: `@MainActor final class HomeService: HomeServiceProtocol`; `private static let baseURL = "https://api.bodymetric.com.br/api/home"`; `init(networkClient: any NetworkClientProtocol)`; `fetchHomeData()` builds GET URLRequest, calls `networkClient.data(for:)`, handles 200 → decode `HomeScreenData`, other → throw `WorkoutPlanError.serverError(statusCode)`, transport → throw `WorkoutPlanError.networkError(error)`; `Logger.error` at all catch sites; register in BodyMetric target; run T002 — all tests must pass; depends on T004, T005

- [x] T007 Populate `Features/Workout/ViewModels/TodayViewModel.swift`: `@Observable @MainActor final class TodayViewModel`; `var loadState: HomeLoadState = .idle`; computed `var hasActivePlan: Bool`, `var workoutPlan: WorkoutDayPlanSummary?`, `var exercisesForToday: [TodayExercise]`; `func loadHomeData(using service: any HomeServiceProtocol) async` — guard against concurrent calls, sets `.loading`, traces `home_data_load_started`, on success `.loaded(data)` + traces `home_data_load_success`, on error `.failed(message)` + traces `home_data_load_failed`; `func reload(using service: any HomeServiceProtocol) async` — resets to `.idle` then calls `loadHomeData`; register in BodyMetric target; run T003 — all tests must pass; depends on T004, T006

**Checkpoint**: All foundational tests pass. Story phases can begin.

---

## Phase 3: User Story 1 — User sees their current workout plan (Priority: P1) 🎯 MVP

**Goal**: When the user has an active plan, the home screen shows a populated workout card with name, exercises count, sets count, duration, and a "Start Workout" button. Menu has "New Workout Plan" disabled and "My Plans" enabled.

**Independent Test**: Inject a mock service returning a plan. Open TodayView. Verify the workout card shows the plan details and "Start Workout" button. Verify menu state.

### Implementation for US1

- [x] T008 [P] [US1] Update `Features/Workout/Views/Components/HomeMenuView.swift`: add `var hasActivePlan: Bool = false` parameter; add `private func effectiveIsActive(for item: HomeMenuItem) -> Bool` — returns `!hasActivePlan` for id "newPlan", `hasActivePlan` for id "myPlans", `item.isActive` for all others; update `menuItemRow(_:)` to use `effectiveIsActive` instead of `item.isActive` for the disabled state and SOON badge logic; also update `Button.disabled(!item.isActive)` to use `!effectiveIsActive(for: item)`

- [x] T009 [US1] Refactor `Features/Workout/Views/TodayView.swift`: (1) Add `let viewModel: TodayViewModel` parameter; add `let homeService: any HomeServiceProtocol` parameter; (2) Remove `let workout: WorkoutSession` and `let streak: WorkoutStreak` parameters; (3) Add `.task { await viewModel.loadHomeData(using: homeService) }` to the NavigationStack; (4) Replace `workoutHeroCard` with a conditional view: when `loadState == .loading` → show `workoutCardSkeleton` (a `RoundedRectangle(cornerRadius: 28).fill(GrayscalePalette.surface).frame(height: 200)` with shimmer animation or opacity pulse); when `loadState == .loaded` and `viewModel.workoutPlan != nil` → show `populatedWorkoutCard(viewModel.workoutPlan!)` displaying plan name, `numberOfExercisesTotal`, `numberSetsTotal`, `timeEstimateToFinishes`, and a "Start Workout" button styled like the existing hero card; (5) Pass `hasActivePlan: viewModel.hasActivePlan` to `HomeMenuView`; (6) Update `#Preview` to provide a `TodayViewModel` and a preview-stub `HomeServiceProtocol`; depends on T007, T008

- [x] T010 [US1] Update `Features/Navigation/MainTabView.swift`: add `let homeService: any HomeServiceProtocol` parameter; in `TabContent`, change `TodayView(workout: .mockToday, streak: .mockStreak, ...)` to `TodayView(viewModel: TodayViewModel(), userName: ..., networkClient: networkClient, onSignOut: ..., homeService: homeService)`; depends on T009

- [x] T011 [US1] Update `App/BodyMetricApp.swift`: create `let hs = HomeService(networkClient: client)` alongside other service creation; pass `homeService: hs` to `MainTabView(...)` call; depends on T010

**Checkpoint**: US1 fully functional. Open app with active plan → skeleton → populated workout card → "Start Workout" button. Menu items correctly enabled/disabled.

---

## Phase 4: User Story 2 — User with no plan sees empty state (Priority: P2)

**Goal**: When the user has no plan, the workout card shows "No workout plan registered" and a "New Workout Plan" button that opens the wizard.

**Independent Test**: Inject a mock service returning nil `currentWorkoutDayPlan`. Open TodayView. Verify empty state card and button that opens the wizard.

- [x] T012 [US2] In `Features/Workout/Views/TodayView.swift`: add empty state workout card view (when `loadState == .loaded` and `viewModel.workoutPlan == nil`): `RoundedRectangle` card styled like the hero card containing a `Text("No workout plan registered")` label and a `Button("New Workout Plan") { showWizard = true }` styled as a secondary CTA using `WorkoutPalette.accent`; the `showWizard = true` action reuses the existing `@State private var showWizard` that already triggers the wizard; depends on T009

**Checkpoint**: US1 AND US2 functional. Users with and without plans see correct states.

---

## Phase 5: User Story 3 — User sees today's exercises (Priority: P3)

**Goal**: An exercises card appears when `exercisesForToday` is non-empty; no card when empty or absent.

**Independent Test**: Mock service returning exercises → exercises card visible. Mock service returning empty → no exercises card.

- [x] T013 [US3] In `Features/Workout/Views/TodayView.swift`: replace the existing `exerciseMenuSection` (which currently reads from the mock `workout.exercises`) with a conditional view: when `viewModel.exercisesForToday.isEmpty` → show nothing; when non-empty → show `exercisesCard(viewModel.exercisesForToday)` — a card styled like the existing exercise list that displays each exercise's `name` in a list row; also replace `exerciseMenuSection` skeleton with an appropriate placeholder or simply hide it while loading; depends on T009

**Checkpoint**: All three user stories functional.

---

## Final Phase: Polish & Cross-Cutting Concerns

- [x] T014 [P] Verify all new Swift files (`HomeModels.swift`, `HomeServiceProtocol.swift`, `HomeService.swift`, `TodayViewModel.swift`, `HomeServiceTests.swift`, `TodayViewModelTests.swift`) are registered in the correct Xcode targets; confirm build has no "file not found" warnings
- [x] T015 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED with no new errors

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1**: T001 — no dependencies
- **Phase 2**: T002 + T003 (tests, parallel) → T004 + T005 (parallel) → T006 → T007
- **Phase 3 (US1)**: T008 (parallel with T007) → T009 → T010 → T011
- **Phase 4 (US2)**: T012 depends on T009
- **Phase 5 (US3)**: T013 depends on T009
- **Final**: T014 + T015 after all story phases

### Parallel Opportunities

```
Phase 2:
  T002 ‖ T003 ‖ T004 ‖ T005   (all parallel — different files)
  T006 (needs T004, T005)
  T007 (needs T006)
  T008 (parallel with T007 — different file)

Phase 3:
  T009 (needs T007 + T008)
  T010 → T011

Phase 4 + 5:
  T012 ‖ T013   (both depend on T009; parallel — same file but different sections)
  Note: T012 and T013 both modify TodayView.swift — run sequentially

Final:
  T014 ‖ T015
```

---

## Implementation Strategy

### MVP (User Story 1 only — 11 tasks)

1. Phase 1: T001
2. Phase 2: T002 + T003 → T004 + T005 → T006 → T007 + T008
3. Phase 3: T009 → T010 → T011
4. **STOP**: Verify populated workout card with live data
5. Final: T014 + T015

### Full Delivery (all stories — 15 tasks)

MVP + T012 (US2 empty state) + T013 (US3 exercises card) + final phase.

---

## Notes

- `TodayView` still keeps `let streak: WorkoutStreak` removed and replaced by `TodayViewModel` — the streak ribbon will continue to use mock data in this feature slice (not in the API response)
- `HomeLoadState` requires `Equatable`; make `HomeScreenData`, `WorkoutDayPlanSummary`, and `TodayExercise` all `Equatable` so the `loaded(HomeScreenData)` case works
- `effectiveIsActive` in `HomeMenuView` overrides only "newPlan" and "myPlans" — all other items retain their static `isActive` values
- Commit convention: `✨ T007: add TodayViewModel with HomeLoadState machine`
