# Tasks: Start Workout Flow

**Input**: Design documents from `/specs/018-start-workout-flow/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Scope**: 3 new files + 3 modified files. Reuses existing `CheckInView`, `ActiveSessionView`, `ActiveSessionViewModel`. Wires the "Start Workout" button to the real API flow.

**Tests**: Constitution Principle II requires ≥ 90% coverage. Test tasks included.

---

## Phase 1: Setup

No new directories, packages, or project files required. The `Services/WorkoutExecution/` directory will be created when the service files are written.

---

## Phase 2: Foundational — New Models and Home Model Update (blocking all story phases)

**Purpose**: Create all request/response DTOs used by the service and ViewModel, and add `actualWeekNumber` to the home screen plan summary. All downstream tasks depend on these types compiling.

- [X] T001 Create `Models/WorkoutExecutionModels.swift` with: (1) `struct StartSessionRequest: Codable { let planId: Int; let actualWeekNumber: Int; let feeling: String }`; (2) `struct StartSessionResponse: Decodable { let id: String; let planId: Int; let actualWeekNumber: Int; let feeling: String; let exercises: [SessionExercise] }`; (3) `struct SessionExercise: Decodable, Identifiable { let id: String; let name: String; let muscle: String; let restSeconds: Int; let sets: [SessionSet]; let pr: SessionPR? }`; (4) `struct SessionSet: Decodable { let targetReps: Int; let prevWeight: Double; let prevReps: Int }`; (5) `struct SessionPR: Decodable { let weight: Double; let reps: Int }`; (6) `extension StartSessionResponse { func toWorkoutSession() -> WorkoutSession { ... } }` mapping response to `WorkoutSession` using existing `WorkoutExercise`, `WorkoutSet`, `PRRecord` types from `Features/Workout/Models/WorkoutModels.swift`

- [X] T002 [P] Update `Models/HomeModels.swift`: add `let actualWeekNumber: Int?` to `WorkoutDayPlanSummary` (after `timeEstimateToFinish`); add `actualWeekNumber: 1` to the preview stub's `WorkoutDayPlanSummary` constructor in `Features/Workout/Views/TodayView.swift` `PreviewHomeServiceStub`; existing Decodable/test code does not need changes (optional field)

**Checkpoint**: Models compile. T003–T010 can now run in their respective phases.

---

## Phase 3: User Story 1 — Navigate to Ready to Lift and Select Feeling (Priority: P1) 🎯 MVP

**Goal**: Tapping "Start Workout" on the home screen opens `CheckInView` displaying the plan name, exercise count, and estimated duration. The "Begin session" button is disabled until a feeling (Low/Good/Strong) is selected.

**Independent Test**: Present `CheckInView` with mock plan data (planId: 4, planName: "Chest Day", numberOfExercises: 5, estimatedMinutes: 52, actualWeekNumber: 1). Verify the plan name and description text render correctly, the "Begin session" button is disabled initially, and becomes enabled after selecting a mood. No API call needed for this story.

### Implementation for US1

- [X] T003 [US1] Update `Features/Workout/Views/CheckInView.swift`: (1) replace `let workout: WorkoutSession` and `let onBegin: (String) -> Void` parameters with `let planId: Int`, `let planName: String`, `let numberOfExercises: Int`, `let estimatedMinutes: Int`, `let actualWeekNumber: Int`, `let service: any WorkoutExecutionServiceProtocol`; (2) in the program label at the top, replace `workout.program.uppercased()` with `"WEEK \(actualWeekNumber)"` and `workout.dayIndex` with `actualWeekNumber`; (3) in the description text, replace `workout.name.lowercased()` with `planName.lowercased()`, `workout.exercises.count` with `numberOfExercises`, `workout.estimatedMinutes` with `estimatedMinutes`; (4) add `@State private var viewModel = ReadyToLiftViewModel()` and `@State private var path = NavigationPath()`; (5) wrap the view body root `ZStack` in `NavigationStack(path: $path)`; (6) keep all existing `mood`, `warmups`, `dismiss` state unchanged; depends on T001, T002

- [X] T004 [US1] Update `Features/Workout/Views/TodayView.swift`: (1) add `@State private var showCheckIn = false`; (2) replace the empty `// Start workout — destination handled by future feature` comment in the `populatedWorkoutCard` button action with `showCheckIn = true`; (3) add `.fullScreenCover(isPresented: $showCheckIn)` presenting `CheckInView(planId: viewModel.workoutPlan!.id, planName: viewModel.workoutPlan!.name, numberOfExercises: viewModel.workoutPlan!.numberOfExercisesTotal, estimatedMinutes: viewModel.workoutPlan!.timeEstimateToFinish, actualWeekNumber: viewModel.workoutPlan?.actualWeekNumber ?? 1, service: WorkoutExecutionService(networkClient: networkClient))` — guard with `if let plan = viewModel.workoutPlan` inside the cover to avoid force-unwrap; depends on T003

**Checkpoint**: US1 complete. "Start Workout" opens CheckInView with correct plan data. Feeling selection enables "Begin session".

---

## Phase 4: User Story 2 — Begin Session and Navigate to Workout Execution (Priority: P2)

**Goal**: Tapping "Begin session" calls `POST /api/work-executions/start`, shows a loading indicator during the request, and navigates to `ActiveSessionView` with real exercise blocks on success.

**Independent Test**: Inject a mock `WorkoutExecutionServiceProtocol` that returns a `StartSessionResponse` fixture (1 exercise, 2 sets). Tap "Begin session" with mood `.ok`. Assert: `viewModel.isSubmitting == true` during call; after success `viewModel.sessionResponse != nil`; `sessionResponse.toWorkoutSession().exercises.count == 1`; mock received `feeling == "OK"` (uppercase).

### Implementation for US2

- [X] T005 [US2] Create `Services/WorkoutExecution/WorkoutExecutionServiceProtocol.swift`: define `@MainActor protocol WorkoutExecutionServiceProtocol: AnyObject { func startSession(_ request: StartSessionRequest) async throws -> StartSessionResponse }`; add doc comment: "Starts a new workout execution session. `NetworkClient` handles Bearer token injection. Throws `WorkoutPlanError.serverError` for non-200/201, `.decodingError` for malformed response, `.networkError` for transport failures."

- [X] T006 [P] [US2] Create `Services/WorkoutExecution/WorkoutExecutionService.swift`: `@MainActor final class WorkoutExecutionService: WorkoutExecutionServiceProtocol` with `init(networkClient: any NetworkClientProtocol)`; implement `startSession`: build `POST https://api.bodymetric.com.br/api/work-executions/start` request with `Content-Type: application/json` header and `JSONEncoder().encode(request)` body; call `networkClient.data(for:)`; accept 200 and 201 as success; decode `StartSessionResponse` via `JSONDecoder()`; throw `WorkoutPlanError.decodingError` on decode failure; throw `WorkoutPlanError.serverError(http.statusCode)` for non-200/201; throw `WorkoutPlanError.networkError(error)` on encode/transport failure; log `"WorkoutExecutionService: startSession planId:\(request.planId) feeling:\(request.feeling)"` at INFO before call; log HTTP status at INFO; log all errors at ERROR (no tokens or PII); depends on T001, T005

- [X] T007 [P] [US2] Create `Features/Workout/ViewModels/ReadyToLiftViewModel.swift`: `@Observable @MainActor final class ReadyToLiftViewModel`; (1) `enum LoadState: Equatable { case idle, submitting, failed(String) }`; (2) `var loadState: LoadState = .idle`; (3) `var sessionResponse: StartSessionResponse? = nil`; (4) `var isSubmitting: Bool { loadState == .submitting }`; (5) `func beginSession(planId: Int, actualWeekNumber: Int, feeling: String, using service: any WorkoutExecutionServiceProtocol) async` — guard `!isSubmitting`, set `.submitting`, log `session_begin_started planId:\(planId) feeling:\(feeling.uppercased())`; build `StartSessionRequest(planId: planId, actualWeekNumber: actualWeekNumber, feeling: feeling.uppercased())`; call `service.startSession(request)`; on success set `sessionResponse = response` and `loadState = .idle` and log `session_begin_success`; on error log `session_begin_failed` via `Logger.error` and set `loadState = .failed("Could not start your session. Please try again.")`; depends on T001, T005

- [X] T008 [US2] Update `Features/Workout/Views/CheckInView.swift` to wire the ViewModel: (1) replace the existing `Button { guard let m = mood else { return }; onBegin(m.rawValue) }` action with `Button { guard let m = mood else { return }; Task { await viewModel.beginSession(planId: planId, actualWeekNumber: actualWeekNumber, feeling: m.rawValue, using: service) } }`; (2) update button label to show `ProgressView().tint(GrayscalePalette.background)` when `viewModel.isSubmitting`, otherwise the existing `HStack` with "Begin session" text and chevron; (3) update button `.disabled` to `mood == nil || viewModel.isSubmitting`; (4) add error banner below the warmup section and above the Begin CTA: `if case .failed(let msg) = viewModel.loadState { Text(msg).font(.system(size: 12, design: .monospaced)).foregroundStyle(GrayscalePalette.secondary).multilineTextAlignment(.center).padding(.horizontal, 20).padding(.bottom, 8) }`; (5) add `.navigationDestination(for: StartSessionResponse.self) { response in ActiveSessionView(viewModel: ActiveSessionViewModel(workout: response.toWorkoutSession(), mood: response.feeling), onComplete: { path.removeLast() }) }` on the NavigationStack; (6) add `.onChange(of: viewModel.sessionResponse) { _, response in if let r = response { path.append(r) } }` on the NavigationStack; depends on T003, T006, T007

**Checkpoint**: US1 + US2 complete. Full happy path works: Start Workout → CheckInView → feeling selection → Begin session → API call → ActiveSessionView.

---

## Phase 5: User Story 3 — Session Start Failure Handling + Tests (Priority: P3)

**Goal**: When the session-start request fails, the error message appears on CheckInView, the "Begin session" button re-enables, and the previously selected feeling remains visible. Tests cover all states.

**Independent Test**: Set mock to throw `WorkoutPlanError.serverError(500)`. Call `beginSession`. Assert `viewModel.loadState == .failed(...)` and `viewModel.isSubmitting == false`. Verify the error message is non-empty.

### Implementation for US3

- [X] T009 [P] [US3] Create `BodyMetricTests/Services/WorkoutExecutionServiceTests.swift`: `@MainActor final class WorkoutExecutionServiceTests: XCTestCase` with `MockNetworkClient`; (1) `test_startSession_200_decodesResponse` — JSON fixture with id, planId, actualWeekNumber, feeling, one exercise with two sets; assert `result.id == "exec-1"`, `result.exercises.count == 1`, `result.exercises[0].sets.count == 2`; (2) `test_startSession_201_doesNotThrow` — status 201, same JSON, assert no throw; (3) `test_startSession_400_throwsServerError` — status 400, assert throws `WorkoutPlanError.serverError(400)`; (4) `test_startSession_sendsPOSTRequest` — assert `capturedRequests.last?.httpMethod == "POST"` and URL contains `/work-executions/start`; (5) `test_startSession_networkError_throws` — set `mockClient.errorToThrow = URLError(.notConnectedToInternet)`, assert throws `WorkoutPlanError.networkError`; (6) `test_startSession_requestBodyContainsFeelingAndPlanId` — encode request, decode body, assert `feeling == "OK"` and `planId == 4`; depends on T006, T001

- [X] T010 [P] [US3] Create `BodyMetricTests/Features/ReadyToLiftViewModelTests.swift`: `@MainActor final class ReadyToLiftViewModelTests: XCTestCase` with `MockWorkoutExecutionService: WorkoutExecutionServiceProtocol`; (1) `test_beginSession_success_setsSessionResponse` — return fixture response, assert `sut.sessionResponse != nil` and `sut.loadState == .idle`; (2) `test_beginSession_success_uppercasesFeeling` — call with `feeling: "ok"`, assert `mockService.lastRequest?.feeling == "OK"`; (3) `test_beginSession_success_isSubmittingFalseAfter` — assert `sut.isSubmitting == false` after success; (4) `test_beginSession_failure_setsFailedState` — throw `.serverError(500)`, assert `sut.loadState` is `.failed`; (5) `test_beginSession_failure_sessionResponseNil` — throw error, assert `sut.sessionResponse == nil`; (6) `test_beginSession_failure_isSubmittingFalseAfter` — assert `sut.isSubmitting == false` after failure; (7) `test_beginSession_reentryGuard` — set `sut.loadState = .submitting`, call `beginSession`, assert `mockService.callCount == 0`; depends on T007

**Checkpoint**: All user stories complete. Full flow is tested end-to-end.

---

## Final Phase: Polish

- [X] T011 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED with no new errors

---

## Dependencies

```
T001 (WorkoutExecutionModels)
T002 [P] (HomeModels actualWeekNumber — parallel to T001)
    ↓
T003 [US1] (CheckInView params refactor — depends T001+T002 for types)
    ↓
T004 [US1] (TodayView wiring — depends T003 for CheckInView signature)

T001 + T002
    ↓
T005 [US2] (WorkoutExecutionServiceProtocol)
    ↓
T006 [P] [US2] + T007 [P] [US2]   (Service impl | ReadyToLiftViewModel — parallel, different files)
    ↓
T008 [US2] (CheckInView VM wiring — depends T003 + T006 + T007)

T006 → T009 [P] [US3]   (service tests)
T007 → T010 [P] [US3]   (VM tests)
T009 + T010 run in parallel (different files)

T001..T010 → T011 (build)
```

---

## Notes

- T001 and T002 are [P] because they are different files with no cross-dependency
- T006 and T007 are [P] — both depend on T005 but write to different files
- T009 and T010 are [P] — different test files, both independent
- `MockWorkoutExecutionService` in ReadyToLiftViewModelTests needs: `var lastRequest: StartSessionRequest?`, `var callCount = 0`, `var responseToReturn: StartSessionResponse?`, `var errorToThrow: Error?`
- The `StartSessionResponse` must conform to `Hashable` for use in `NavigationPath` — add `extension StartSessionResponse: Hashable` in `WorkoutExecutionModels.swift`
- Constitution III: all catch sites in `WorkoutExecutionService` and `ReadyToLiftViewModel` must log via `Logger.error` before propagating
- Constitution VII: `WorkoutExecutionService` uses `networkClient.data(for:)` — Bearer token injection is automatic; no token appears in logs
- The `CheckInView.Mood` enum's `rawValue.uppercased()` (e.g., `"ok".uppercased()` → `"OK"`) is the feeling conversion specified by FR-005
