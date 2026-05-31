# Tasks: Edit Existing Workout Plan

**Input**: Design documents from `/specs/017-edit-workout-plan/`  
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Scope**: 8 modified files, 0 new files. Adds edit mode to the existing wizard and wires the "My Plan" menu item.

**Tests**: Constitution Principle II requires ≥ 90% coverage. Test tasks are included.

---

## Phase 1: Setup

No new directories, packages, or project files required. Proceed directly to Phase 2.

---

## Phase 2: Foundational — Model and Protocol Update (blocking all story phases)

**Purpose**: Add new Decodable DTOs for `GET /api/workout-plans/current` and the Codable request type for `PUT /api/workout-plans/{id}`, and extend the protocol. All downstream tasks depend on these compiling.

- [X] T001 Add new DTOs to `Models/WorkoutPlanModels.swift`: (1) `struct CurrentWorkoutPlan: Decodable { let id: Int; let days: [CurrentWorkoutPlanDay] }`; (2) `struct CurrentWorkoutPlanDay: Decodable { let id: Int; let plannedDayOfWeek: String; let name: String; let orderIndex: Int; let exerciseBlocks: [CurrentExerciseBlock] }`; (3) `struct CurrentExerciseBlock: Decodable { let exerciseId: Int; let orderIndex: Int; let restSeconds: Int; let targetSets: [CurrentTargetSet] }`; (4) `struct CurrentTargetSet: Decodable { let orderIndex: Int; let targetReps: Int; let targetWeight: Double }`; (5) `struct UpdateWorkoutPlanRequest: Codable { let days: [UpdateWorkoutPlanDayRequest] }`; (6) `struct UpdateWorkoutPlanDayRequest: Codable { let plannedDayOfWeek: String; let name: String; let orderIndex: Int; let isActive: Bool; let exerciseBlocks: [ExerciseBlockRequest] }`

- [X] T002 [P] Add two new method signatures to `Services/WorkoutPlan/WorkoutPlanServiceProtocol.swift`: (1) `func fetchCurrentPlan() async throws -> CurrentWorkoutPlan`; (2) `func updatePlan(id: Int, request: UpdateWorkoutPlanRequest) async throws`; keep all existing methods unchanged

**Checkpoint**: Models and protocol compile. T003–T004 can now run in parallel.

---

## Phase 3: User Story 1 — User sees existing plan pre-filled in wizard (Priority: P1) 🎯 MVP

**Goal**: Tapping "My Plan" opens the wizard pre-loaded with all existing plan data (days, session names, exercises, reps, weight, rest time). A loading skeleton covers the wizard while the fetch is in progress.

**Independent Test**: Launch wizard with a mock `WorkoutPlanServiceProtocol` that returns a `CurrentWorkoutPlan` fixture (1 day, 1 exercise, `exerciseId: 26`, `targetReps: 10`, `targetWeight: 60`). Assert `viewModel.planId == 123`, `viewModel.selectedDays.contains(.monday)`, `viewModel.dayPlans[.monday]?.sessionName == "Chest Day"`, `viewModel.dayPlans[.monday]?.blocks.first?.exerciseId == "26"`, `viewModel.isEditMode == true`.

### Implementation for US1

- [X] T003 [P] [US1] Implement `fetchCurrentPlan()` in `Services/WorkoutPlan/WorkoutPlanService.swift`: build `GET \(Self.baseURL)/current` request; pass to `networkClient.data(for:)`; on 200 decode `CurrentWorkoutPlan` via `JSONDecoder()`, throw `WorkoutPlanError.decodingError` on failure; on 404 throw `WorkoutPlanError.notFound`; on all other codes throw `WorkoutPlanError.serverError(statusCode)`; log status code at INFO; log decode failure at ERROR (no tokens or PII); depends on T001, T002

- [X] T004 [P] [US1] Add edit-mode state and `loadCurrentPlan` to `Features/NewPlan/ViewModels/NewPlanViewModel.swift`: (1) add `enum EditPlanLoadState: Equatable { case idle, loading, loaded, failed(String) }` nested inside the class; (2) add `var planId: Int? = nil`; (3) add `var editPlanLoadState: EditPlanLoadState = .idle`; (4) add `var isEditMode: Bool { planId != nil }` computed property; (5) implement `func loadCurrentPlan(using service: any WorkoutPlanServiceProtocol) async` — guard `editPlanLoadState != .loading`, set `.loading`, call `service.fetchCurrentPlan()`, on success set `planId = plan.id`, rebuild `selectedDays` via `DayOfWeek(fromApiString:)`, set `workoutPlanIds[day] = apiDay.id` per day, build `DayPlan(day:sessionName:blocks:)` per day mapping `CurrentExerciseBlock` sorted by `orderIndex` into `ExerciseBlock` (`exerciseId = String(block.exerciseId)`, use first `targetSet` by `orderIndex` for `targetReps`/`targetWeight`), set `.loaded`; on `WorkoutPlanError.notFound` set `.failed("No active plan found.")`; on other errors call `Logger.error` then set `.failed("Could not load your plan. Please try again.")`; log `edit_plan_load_started`, `edit_plan_load_success planId:\(plan.id) dayCount:\(plan.days.count)`, and errors; depends on T001, T002

- [X] T005 [US1] Update `Features/NewPlan/Views/NewPlanWizardView.swift`: (1) add `let editPlanId: Int?` parameter (add default `= nil` at existing call sites to stay non-breaking); (2) add `.task { if editPlanId != nil { await viewModel.loadCurrentPlan(using: service) } }` on the root `ZStack`; (3) add a loading overlay: `if viewModel.editPlanLoadState == .loading { ZStack { GrayscalePalette.background.ignoresSafeArea(); ProgressView().tint(GrayscalePalette.primary) } }` inside the root `ZStack` so it covers the wizard during pre-fill; (4) in `wizardHeader`, change step label to use `viewModel.isEditMode ? "EDIT PLAN" : "NEW PLAN"` as the mode prefix; (5) in `continueButton` action, when `viewModel.currentStep == 1` and `viewModel.isEditMode` call `viewModel.advance()` directly (skip `saveDays`); when step is a day-config step and `viewModel.isEditMode` call `viewModel.advance()` directly (skip `saveDayConfig`); depends on T003, T004

- [X] T006 [P] [US1] Add service tests to `BodyMetricTests/Services/WorkoutPlanServiceTests.swift`: (1) `test_fetchCurrentPlan_200_success` — mock JSON with `id:123`, one day (`id:456, plannedDayOfWeek:"MONDAY", name:"Chest Day", orderIndex:0, exerciseBlocks:[{exerciseId:26, orderIndex:1, restSeconds:90, targetSets:[{orderIndex:1, targetReps:10, targetWeight:60.0}]}]`), assert `result.id == 123`, `result.days.count == 1`, `result.days[0].id == 456`, `result.days[0].exerciseBlocks[0].exerciseId == 26`; (2) `test_fetchCurrentPlan_404_throwsNotFound` — status 404, assert throws `WorkoutPlanError.notFound`; (3) `test_fetchCurrentPlan_500_throwsServerError` — status 500, assert throws `WorkoutPlanError.serverError(500)`; (4) `test_fetchCurrentPlan_sendGETRequest` — assert `httpMethod == "GET"` and URL contains `/workout-plans/current`; depends on T001, T003

- [X] T007 [P] [US1] Add ViewModel tests to `BodyMetricTests/Features/NewPlanViewModelTests.swift`: (1) `test_loadCurrentPlan_prefillsAllState` — make `MockWorkoutPlanService` return a fixture `CurrentWorkoutPlan(id:123, days:[...])` with one Monday day (`id:456, name:"Chest Day"`, one block `exerciseId:26, restSeconds:90, targetReps:10, targetWeight:60`), call `await sut.loadCurrentPlan(using:mockService)`, assert `sut.planId == 123`, `sut.selectedDays.contains(.monday)`, `sut.dayPlans[.monday]?.sessionName == "Chest Day"`, `sut.dayPlans[.monday]?.blocks.first?.exerciseId == "26"`, `sut.dayPlans[.monday]?.blocks.first?.restSeconds == 90`, `sut.workoutPlanIds[.monday] == 456`, `sut.isEditMode == true`, `sut.editPlanLoadState == .loaded`; (2) `test_loadCurrentPlan_notFound_setsFailedState` — make mock throw `WorkoutPlanError.notFound`, assert `sut.editPlanLoadState == .failed("No active plan found.")`; (3) `test_loadCurrentPlan_networkError_setsFailedState` — make mock throw `WorkoutPlanError.networkError(URLError(.notConnectedToInternet))`, assert `sut.editPlanLoadState` is `.failed`; (4) `test_loadCurrentPlan_reentryGuard` — set `sut.editPlanLoadState = .loading`, call `loadCurrentPlan`, assert fetch count is 0; depends on T004; also extend `MockWorkoutPlanService` (already defined in `NewPlanViewModelTests.swift`) with `currentPlanToReturn: CurrentWorkoutPlan?` and `func fetchCurrentPlan()` + `func updatePlan(id:request:)` stubs

**Checkpoint**: US1 complete. Wizard opens pre-filled from a mock service. US2 and US3 can now proceed.

---

## Phase 4: User Story 2 — User edits and saves plan changes (Priority: P2)

**Goal**: After editing fields in the wizard, the user taps "Finish & Save" and the existing plan is updated via `PUT /api/workout-plans/{id}`. No duplicate plan is created.

**Independent Test**: Inject a `CurrentWorkoutPlan(id:123)` into the VM via `loadCurrentPlan`, modify `dayPlans[.monday]?.sessionName` to a new value, call `updatePlan(using:onSuccess:)`, assert the mock service's `updatePlan` was called with `id:123` and a request whose first day has the modified session name, and that `isSaving` is `false` after completion.

### Implementation for US2

- [X] T008 [P] [US2] Implement `updatePlan(id:request:)` in `Services/WorkoutPlan/WorkoutPlanService.swift`: build `PUT \(Self.baseURL)/\(id)` request with `httpMethod = "PUT"`, `Content-Type: application/json`, `httpBody = JSONEncoder().encode(request)`; call `networkClient.data(for:)`; accept 200 and 204 as success; on other status codes throw `WorkoutPlanError.serverError(statusCode)`; on encode failure throw `WorkoutPlanError.networkError(error)`; on transport failure throw `WorkoutPlanError.networkError(error)`; log `edit_plan_update_initiated planId:\(id)` at INFO and errors at ERROR; depends on T001, T002

- [X] T009 [P] [US2] Add `updatePlan(using:onSuccess:)` to `Features/NewPlan/ViewModels/NewPlanViewModel.swift`: guard `planId != nil` and `!isSaving`, set `isSaving = true`, `saveErrorMessage = nil`; build `UpdateWorkoutPlanRequest(days: orderedSelectedDays.map { day in UpdateWorkoutPlanDayRequest(plannedDayOfWeek: day.fullLabel.lowercased(), name: dayPlans[day]!.sessionName, orderIndex: day.orderIndex, isActive: true, exerciseBlocks: dayPlans[day]!.blocks.enumerated().map { idx, block in ExerciseBlockRequest(block: block, orderIndex: idx + 1) }) })`; call `service.updatePlan(id: planId!, request:)`; on success log `edit_plan_update_success planId:\(planId!)` and call `onSuccess()`; on error log `edit_plan_update_failed` via `Logger.error` and set `saveErrorMessage = "Could not update your plan. Please try again."`; always set `isSaving = false`; depends on T004

- [X] T010 [US2] Update `Features/NewPlan/Views/NewPlanWizardView.swift` finish behavior: in `finishButton` action, branch on `viewModel.isEditMode`: when `true`, call `Task { await viewModel.updatePlan(using: service) { viewModel.isPresentingSuccess = true } }`; when `false`, keep existing `viewModel.finish(store: store)` call; no other changes to the wizard; depends on T008, T009

- [X] T011 [P] [US2] Add `updatePlan` ViewModel tests to `BodyMetricTests/Features/NewPlanViewModelTests.swift`: (1) `test_updatePlan_success_callsOnSuccess` — pre-fill VM via `loadCurrentPlan` with a fixture plan, call `await sut.updatePlan(using: mockService) { ... }`, assert `onSuccess` was called and `sut.isSaving == false`; (2) `test_updatePlan_serverError_setsSaveErrorMessage` — make mock's `updatePlan` throw `WorkoutPlanError.serverError(400)`, assert `sut.saveErrorMessage != nil` and `sut.isSaving == false`; (3) `test_updatePlan_request_containsAllSelectedDays` — pre-fill with a 2-day plan, assert the captured `UpdateWorkoutPlanRequest.days.count == 2`; (4) `test_updatePlan_reentryGuard` — set `sut.isSaving = true`, call `updatePlan`, assert mock's call count is 0; depends on T009

- [X] T012 [P] [US2] Add `updatePlan` service tests to `BodyMetricTests/Services/WorkoutPlanServiceTests.swift`: (1) `test_updatePlan_200_success` — status 200, assert no error thrown; (2) `test_updatePlan_204_success` — status 204, assert no error thrown; (3) `test_updatePlan_400_throwsServerError` — status 400, assert throws `WorkoutPlanError.serverError(400)`; (4) `test_updatePlan_sendsPUTRequest` — assert `capturedRequests.last?.httpMethod == "PUT"` and URL contains `/workout-plans/123`; depends on T008

**Checkpoint**: US1 + US2 complete. Full edit flow works end-to-end with mock services.

---

## Phase 5: User Story 3 — Menu item naming and availability (Priority: P3)

**Goal**: The menu shows "My Plan" (singular), enabled only when `hasActivePlan == true`. Tapping it opens the wizard in edit mode. "New Workout Plan" remains always available.

**Independent Test**: With `hasActivePlan = true`, assert "My Plan" row in `HomeMenuView` is active. With `hasActivePlan = false`, assert it is disabled/hidden. Verify the label reads "My Plan" in both states.

### Implementation for US3

- [X] T013 [US3] Update `Features/Workout/Models/HomeMenuModels.swift`: (1) add `case editPlan` to `HomeMenuDestination` enum (keep `today` and `newWorkoutPlan`); (2) in `HomeMenuItem.catalog`, replace the "myPlans" entry with `HomeMenuItem(id: "myPlan", label: "My Plan", subtitle: "Edit your routine", iconName: "dumbbell.fill", isActive: true, isPrimary: false, destination: .editPlan)`; no other catalog entries change

- [X] T014 [P] [US3] Update `Features/Workout/Views/Components/HomeMenuView.swift` `effectiveIsActive(for:)`: change `case "myPlans": return hasActivePlan` to `case "myPlan": return hasActivePlan`; no other changes; depends on T013

- [X] T015 [P] [US3] Update `Features/Workout/Views/TodayView.swift`: (1) add `@State private var showEditWizard = false` alongside existing `showWizard`; (2) add `case .editPlan: showEditWizard = true` in the `onNavigate` switch (after `.newWorkoutPlan` case); (3) add a second `.fullScreenCover(isPresented: $showEditWizard)` presenting `NewPlanWizardView(service: WorkoutPlanService(networkClient: networkClient), dayConfigService: WorkoutDayPlanService(networkClient: networkClient), exerciseService: ExerciseService(networkClient: networkClient), editPlanId: viewModel.workoutPlan?.id)`; `viewModel.workoutPlan` is `WorkoutDayPlanSummary?` with `id: Int` (feature 016); depends on T013, T005

**Checkpoint**: All user stories complete. Full feature is functional end-to-end.

---

## Final Phase: Polish

- [X] T016 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED with no new errors

---

## Dependencies

```
T001 (WorkoutPlanModels DTOs)
T002 [P] (WorkoutPlanServiceProtocol)
    ↓
T003 [P] + T004 [P]   (WorkoutPlanService.fetchCurrentPlan | NewPlanViewModel.loadCurrentPlan — parallel, different files)
    ↓
T005 (NewPlanWizardView editPlanId + loading)
T006 [P] + T007 [P]   (service tests | VM tests — parallel, different files; after T003/T004)

T001+T002
    ↓
T008 [P] + T009 [P]   (WorkoutPlanService.updatePlan | NewPlanViewModel.updatePlan — parallel after T001+T002; T009 also depends on T004 for VM state)
    ↓
T010 (NewPlanWizardView finishButton edit mode)
T011 [P] + T012 [P]   (VM tests | service tests — parallel)

T013 (HomeMenuModels rename + editPlan destination)
    ↓
T014 [P] + T015 [P]   (HomeMenuView key | TodayView wiring — parallel; T015 also depends on T005)

T003..T015 → T016 (build)
```

---

## Notes

- T001 and T002 are both foundational but in different files; run them in parallel
- T003 and T004 are [P] — different files, both depend only on T001+T002
- T008 and T009 are [P] — different files; T009 also needs T004's VM state (planId, isSaving)
- T013 is a blocker for both T014 and T015; T014/T015 can then run in parallel
- T015 depends on T005 (editPlanId parameter must exist in NewPlanWizardView before TodayView uses it)
- `MockWorkoutPlanService` in `NewPlanViewModelTests.swift` must grow to implement the two new protocol methods (`fetchCurrentPlan`, `updatePlan`) — do this as part of T007 when extending the mock
- Constitution III: all new `catch` sites need `Logger.error` calls before propagating or swallowing
- Constitution VII: all new service methods use `networkClient.data(for:)` — token injection is automatic; no token values in log messages
