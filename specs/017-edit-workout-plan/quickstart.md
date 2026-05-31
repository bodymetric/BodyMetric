# Quickstart: Edit Existing Workout Plan

**Date**: 2026-05-17

---

## 1. New models — Models/WorkoutPlanModels.swift (append after existing structs)

```swift
// MARK: - GET /api/workout-plans/current response DTOs

struct CurrentWorkoutPlan: Decodable {
    let id: Int
    let days: [CurrentWorkoutPlanDay]
}

struct CurrentWorkoutPlanDay: Decodable {
    let id: Int
    let plannedDayOfWeek: String
    let name: String
    let orderIndex: Int
    let exerciseBlocks: [CurrentExerciseBlock]
}

struct CurrentExerciseBlock: Decodable {
    let exerciseId: Int
    let orderIndex: Int
    let restSeconds: Int
    let targetSets: [CurrentTargetSet]
}

struct CurrentTargetSet: Decodable {
    let orderIndex: Int
    let targetReps: Int
    let targetWeight: Double
}

// MARK: - PUT /api/workout-plans/{id} request DTOs

struct UpdateWorkoutPlanRequest: Codable {
    let days: [UpdateWorkoutPlanDayRequest]
}

struct UpdateWorkoutPlanDayRequest: Codable {
    let plannedDayOfWeek: String
    let name: String
    let orderIndex: Int
    let isActive: Bool
    let exerciseBlocks: [ExerciseBlockRequest]
}
```

---

## 2. Protocol — Services/WorkoutPlan/WorkoutPlanServiceProtocol.swift (add 2 methods)

```swift
func fetchCurrentPlan() async throws -> CurrentWorkoutPlan
func updatePlan(id: Int, request: UpdateWorkoutPlanRequest) async throws
```

---

## 3. Service implementation — Services/WorkoutPlan/WorkoutPlanService.swift

```swift
func fetchCurrentPlan() async throws -> CurrentWorkoutPlan {
    guard let url = URL(string: "\(Self.baseURL)/current") else {
        throw WorkoutPlanError.networkError(URLError(.badURL))
    }
    let (data, http) = try await networkClient.data(for: URLRequest(url: url))
    switch http.statusCode {
    case 200:
        do { return try JSONDecoder().decode(CurrentWorkoutPlan.self, from: data) }
        catch { throw WorkoutPlanError.decodingError }
    case 404:
        throw WorkoutPlanError.notFound
    default:
        throw WorkoutPlanError.serverError(http.statusCode)
    }
}

func updatePlan(id: Int, request: UpdateWorkoutPlanRequest) async throws {
    guard let url = URL(string: "\(Self.baseURL)/\(id)") else {
        throw WorkoutPlanError.networkError(URLError(.badURL))
    }
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "PUT"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.httpBody = try JSONEncoder().encode(request)
    let (_, http) = try await networkClient.data(for: urlRequest)
    guard [200, 204].contains(http.statusCode) else {
        throw WorkoutPlanError.serverError(http.statusCode)
    }
}
```

---

## 4. ViewModel additions — Features/NewPlan/ViewModels/NewPlanViewModel.swift

```swift
// New state
enum EditPlanLoadState: Equatable {
    case idle, loading, loaded, failed(String)
}

var planId: Int? = nil
var editPlanLoadState: EditPlanLoadState = .idle

var isEditMode: Bool { planId != nil }

// New action — pre-fill wizard state from existing plan
func loadCurrentPlan(using service: any WorkoutPlanServiceProtocol) async {
    guard editPlanLoadState != .loading else { return }
    editPlanLoadState = .loading
    Logger.info("edit_plan_load_started")
    do {
        let plan = try await service.fetchCurrentPlan()
        planId = plan.id
        let days = Set(plan.days.compactMap { DayOfWeek(fromApiString: $0.plannedDayOfWeek) })
        selectedDays = days
        for apiDay in plan.days {
            guard let day = DayOfWeek(fromApiString: apiDay.plannedDayOfWeek) else { continue }
            workoutPlanIds[day] = apiDay.id
            let blocks = apiDay.exerciseBlocks
                .sorted { $0.orderIndex < $1.orderIndex }
                .map { block -> ExerciseBlock in
                    let firstSet = block.targetSets.min(by: { $0.orderIndex < $1.orderIndex })
                    var b = ExerciseBlock()
                    b.exerciseId   = String(block.exerciseId)
                    b.restSeconds  = block.restSeconds
                    b.targetReps   = firstSet?.targetReps   ?? 8
                    b.targetWeight = firstSet?.targetWeight ?? 0
                    return b
                }
            dayPlans[day] = DayPlan(day: day, sessionName: apiDay.name, blocks: blocks)
        }
        editPlanLoadState = .loaded
        Logger.info("edit_plan_load_success planId:\(plan.id) dayCount:\(plan.days.count)")
    } catch WorkoutPlanError.notFound {
        editPlanLoadState = .failed("No active plan found.")
        Logger.info("edit_plan_load_not_found")
    } catch {
        Logger.error("edit_plan_load_failed", error: error)
        editPlanLoadState = .failed("Could not load your plan. Please try again.")
    }
}

// New action — send PUT to update existing plan
func updatePlan(
    using service: any WorkoutPlanServiceProtocol,
    onSuccess: @MainActor @Sendable () -> Void
) async {
    guard let id = planId, !isSaving else { return }
    isSaving = true
    saveErrorMessage = nil
    Logger.info("edit_plan_update_started planId:\(id)")
    let dayRequests = orderedSelectedDays.map { day -> UpdateWorkoutPlanDayRequest in
        let plan = dayPlans[day]!
        return UpdateWorkoutPlanDayRequest(
            plannedDayOfWeek: day.fullLabel.lowercased(),
            name: plan.sessionName,
            orderIndex: day.orderIndex,
            isActive: true,
            exerciseBlocks: plan.blocks.enumerated().map { idx, block in
                ExerciseBlockRequest(block: block, orderIndex: idx + 1)
            }
        )
    }
    do {
        try await service.updatePlan(id: id, request: UpdateWorkoutPlanRequest(days: dayRequests))
        Logger.info("edit_plan_update_success planId:\(id)")
        onSuccess()
    } catch {
        Logger.error("edit_plan_update_failed", error: error)
        saveErrorMessage = "Could not update your plan. Please try again."
    }
    isSaving = false
}
```

---

## 5. Wizard view changes — Features/NewPlan/Views/NewPlanWizardView.swift

```swift
// Add parameter
let editPlanId: Int?                // nil = create mode; non-nil = edit mode

// In body, add:
.task {
    if editPlanId != nil {
        await viewModel.loadCurrentPlan(using: service)
    }
}

// In wizardHeader title VStack:
let modeLabel = viewModel.isEditMode ? "EDIT PLAN" : "NEW PLAN"
Text("\(modeLabel) · STEP \(viewModel.currentStep) OF \(viewModel.totalSteps)")

// continueButton action — step 1 in edit mode just advances (no POST):
if viewModel.currentStep == 1 {
    if viewModel.isEditMode {
        viewModel.advance()
    } else {
        Task { await viewModel.saveDays(using: service) { viewModel.advance() } }
    }
} else if let day = viewModel.currentDayOfWeek {
    if viewModel.isEditMode {
        viewModel.advance()              // no per-day POST in edit mode
    } else {
        Task { await viewModel.saveDayConfig(for: day, using: dayConfigService) { viewModel.advance() } }
    }
}

// finishButton action — in edit mode call updatePlan instead of finish(store:):
if viewModel.isEditMode {
    Task { await viewModel.updatePlan(using: service) { viewModel.isPresentingSuccess = true } }
} else {
    viewModel.finish(store: store)
}

// Loading overlay when editPlanId != nil and editPlanLoadState == .loading:
if viewModel.editPlanLoadState == .loading {
    // Cover entire wizard with a skeleton/spinner overlay
    ZStack {
        GrayscalePalette.background.ignoresSafeArea()
        ProgressView()
            .tint(GrayscalePalette.primary)
    }
}
```

---

## 6. Menu model changes — Features/Workout/Models/HomeMenuModels.swift

```swift
// HomeMenuDestination — add case:
case editPlan

// HomeMenuItem.catalog — replace "myPlans" entry:
HomeMenuItem(
    id: "myPlan",                          // was "myPlans"
    label: "My Plan",                      // was "My Plans"
    subtitle: "Edit your routine",         // was "Saved routines"
    iconName: "dumbbell.fill",
    isActive: true,                        // was false (was coming-soon)
    isPrimary: false,
    destination: .editPlan                 // was nil
),
```

---

## 7. HomeMenuView — effectiveIsActive key update

```swift
// Change:
case "myPlans": return hasActivePlan
// To:
case "myPlan": return hasActivePlan
```

---

## 8. TodayView — handle editPlan destination

```swift
// In onNavigate switch:
case .editPlan:
    showEditWizard = true

// New state variable:
@State private var showEditWizard = false

// New fullScreenCover (alongside the existing showWizard cover):
.fullScreenCover(isPresented: $showEditWizard) {
    NewPlanWizardView(
        service: WorkoutPlanService(networkClient: networkClient),
        dayConfigService: WorkoutDayPlanService(networkClient: networkClient),
        exerciseService: ExerciseService(networkClient: networkClient),
        editPlanId: viewModel.workoutPlan?.id
    )
}
```

---

## 9. Test fixture snapshots

### WorkoutPlanServiceTests — fetchCurrentPlan 200

```json
{
  "id": 123,
  "days": [
    {
      "id": 456,
      "plannedDayOfWeek": "MONDAY",
      "name": "Chest Day",
      "orderIndex": 0,
      "exerciseBlocks": [
        {
          "exerciseId": 26,
          "orderIndex": 1,
          "restSeconds": 90,
          "targetSets": [{"orderIndex": 1, "targetReps": 10, "targetWeight": 60.0}]
        }
      ]
    }
  ]
}
```

### NewPlanViewModelTests — loadCurrentPlan mapping

```swift
// Given CurrentWorkoutPlan above is returned by mock service:
// Then:
XCTAssertEqual(sut.planId, 123)
XCTAssertTrue(sut.selectedDays.contains(.monday))
XCTAssertEqual(sut.dayPlans[.monday]?.sessionName, "Chest Day")
XCTAssertEqual(sut.dayPlans[.monday]?.blocks.first?.exerciseId, "26")
XCTAssertEqual(sut.dayPlans[.monday]?.blocks.first?.targetReps, 10)
XCTAssertEqual(sut.workoutPlanIds[.monday], 456)
XCTAssertTrue(sut.isEditMode)
```
