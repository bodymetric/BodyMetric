# Quickstart: Start Workout Flow

**Date**: 2026-05-18

---

## 1. HomeModels.swift — add `actualWeekNumber` to `WorkoutDayPlanSummary`

```swift
struct WorkoutDayPlanSummary: Decodable, Equatable {
    let id: Int
    let name: String
    let dayOfWeek: String
    let numberOfExercisesTotal: Int
    let numberSetsTotal: Int
    let timeEstimateToFinish: Int
    let actualWeekNumber: Int?   // NEW
}
```

Update preview stub and test fixtures: add `actualWeekNumber: 1` to `WorkoutDayPlanSummary` constructors.

---

## 2. New file: Models/WorkoutExecutionModels.swift

```swift
struct StartSessionRequest: Codable {
    let planId: Int
    let actualWeekNumber: Int
    let feeling: String
}

struct StartSessionResponse: Decodable {
    let id: String
    let planId: Int
    let actualWeekNumber: Int
    let feeling: String
    let exercises: [SessionExercise]
}

struct SessionExercise: Decodable, Identifiable {
    let id: String
    let name: String
    let muscle: String
    let restSeconds: Int
    let sets: [SessionSet]
    let pr: SessionPR?
}

struct SessionSet: Decodable {
    let targetReps: Int
    let prevWeight: Double
    let prevReps: Int
}

struct SessionPR: Decodable {
    let weight: Double
    let reps: Int
}

extension StartSessionResponse {
    func toWorkoutSession() -> WorkoutSession {
        WorkoutSession(
            id: id,
            name: "",
            program: "Week \(actualWeekNumber)",
            dayIndex: actualWeekNumber,
            estimatedMinutes: 0,
            exercises: exercises.map { ex in
                WorkoutExercise(
                    id: ex.id,
                    name: ex.name,
                    muscle: ex.muscle,
                    restSeconds: ex.restSeconds,
                    sets: ex.sets.map { WorkoutSet(targetReps: $0.targetReps, prevWeight: $0.prevWeight, prevReps: $0.prevReps) },
                    pr: ex.pr.map { PRRecord(weight: $0.weight, reps: $0.reps) }
                )
            }
        )
    }
}
```

---

## 3. New file: Services/WorkoutExecution/WorkoutExecutionServiceProtocol.swift

```swift
@MainActor
protocol WorkoutExecutionServiceProtocol: AnyObject {
    func startSession(_ request: StartSessionRequest) async throws -> StartSessionResponse
}
```

---

## 4. New file: Services/WorkoutExecution/WorkoutExecutionService.swift

```swift
@MainActor
final class WorkoutExecutionService: WorkoutExecutionServiceProtocol {
    private static let baseURL = "https://api.bodymetric.com.br/api/work-executions"
    private let networkClient: any NetworkClientProtocol

    init(networkClient: any NetworkClientProtocol) { self.networkClient = networkClient }

    func startSession(_ request: StartSessionRequest) async throws -> StartSessionResponse {
        guard let url = URL(string: "\(Self.baseURL)/start") else {
            throw WorkoutPlanError.networkError(URLError(.badURL))
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try { do { return try JSONEncoder().encode(request) }
                                    catch { throw WorkoutPlanError.networkError(error) } }()

        Logger.info("WorkoutExecutionService: startSession planId:\(request.planId) feeling:\(request.feeling)", category: .network)
        let (data, http): (Data, HTTPURLResponse)
        do { (data, http) = try await networkClient.data(for: urlRequest) }
        catch { Logger.error("WorkoutExecutionService: startSession network failure", error: error, category: .network)
                throw WorkoutPlanError.networkError(error) }

        Logger.info("WorkoutExecutionService: startSession HTTP \(http.statusCode)", category: .network)
        guard [200, 201].contains(http.statusCode) else {
            throw WorkoutPlanError.serverError(http.statusCode)
        }
        do { return try JSONDecoder().decode(StartSessionResponse.self, from: data) }
        catch { Logger.error("WorkoutExecutionService: startSession decode failure", error: error, category: .network)
                throw WorkoutPlanError.decodingError }
    }
}
```

---

## 5. New file: Features/Workout/ViewModels/ReadyToLiftViewModel.swift

```swift
@Observable
@MainActor
final class ReadyToLiftViewModel {
    enum LoadState: Equatable {
        case idle, submitting, failed(String)
    }

    var loadState: LoadState = .idle
    var sessionResponse: StartSessionResponse? = nil

    var isSubmitting: Bool { loadState == .submitting }

    func beginSession(
        planId: Int,
        actualWeekNumber: Int,
        feeling: String,
        using service: any WorkoutExecutionServiceProtocol
    ) async {
        guard !isSubmitting else { return }
        loadState = .submitting
        Logger.info("session_begin_started planId:\(planId) feeling:\(feeling)")
        let request = StartSessionRequest(
            planId: planId,
            actualWeekNumber: actualWeekNumber,
            feeling: feeling.uppercased()
        )
        do {
            let response = try await service.startSession(request)
            sessionResponse = response
            loadState = .idle
            Logger.info("session_begin_success planId:\(planId)")
        } catch {
            Logger.error("session_begin_failed", error: error)
            loadState = .failed("Could not start your session. Please try again.")
        }
    }
}
```

---

## 6. Update: Features/Workout/Views/CheckInView.swift

Replace `workout: WorkoutSession` + `onBegin: (String) -> Void` params with plan context:

```swift
struct CheckInView: View {
    let planId: Int
    let planName: String
    let numberOfExercises: Int
    let estimatedMinutes: Int
    let actualWeekNumber: Int
    let service: any WorkoutExecutionServiceProtocol

    @State private var viewModel = ReadyToLiftViewModel()
    @State private var path = NavigationPath()
    // keep existing: @State private var mood / warmups / dismiss
    ...
}
```

In the description text, replace `workout.name` → `planName`, `workout.exercises.count` → `numberOfExercises`, `workout.estimatedMinutes` → `estimatedMinutes`.

Replace the `Button { onBegin(m.rawValue) }` action:
```swift
Button {
    guard let m = mood else { return }
    Task {
        await viewModel.beginSession(
            planId: planId,
            actualWeekNumber: actualWeekNumber,
            feeling: m.rawValue,
            using: service
        )
    }
} label: {
    if viewModel.isSubmitting {
        ProgressView().tint(GrayscalePalette.background)
    } else {
        HStack(spacing: 8) {
            Text("Begin session").font(...)
            Image(systemName: "chevron.right")
        }
    }
}
.disabled(mood == nil || viewModel.isSubmitting)
```

Add error banner when `loadState == .failed(let msg)`:
```swift
if case .failed(let msg) = viewModel.loadState {
    Text(msg)
        .font(.system(size: 13, design: .monospaced))
        .foregroundStyle(GrayscalePalette.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)
}
```

Add NavigationPath navigation to ActiveSessionView on success:
```swift
.navigationDestination(for: StartSessionResponse.self) { response in
    ActiveSessionView(
        viewModel: ActiveSessionViewModel(
            workout: response.toWorkoutSession(),
            mood: response.feeling
        ),
        onComplete: { path.removeLast() }
    )
}
.onChange(of: viewModel.sessionResponse) { _, response in
    if let r = response { path.append(r) }
}
```

Wrap body in `NavigationStack(path: $path)` when used from TodayView fullScreenCover.

---

## 7. Update: Features/Workout/Views/TodayView.swift — wire "Start Workout"

```swift
@State private var showCheckIn = false

// Replace placeholder button action:
Button {
    showCheckIn = true
} label: { ... }

// Add fullScreenCover:
.fullScreenCover(isPresented: $showCheckIn) {
    if let plan = viewModel.workoutPlan {
        CheckInView(
            planId: plan.id,
            planName: plan.name,
            numberOfExercises: plan.numberOfExercisesTotal,
            estimatedMinutes: plan.timeEstimateToFinish,
            actualWeekNumber: plan.actualWeekNumber ?? 1,
            service: WorkoutExecutionService(networkClient: networkClient)
        )
    }
}
```

---

## 8. Test fixtures

### WorkoutExecutionServiceTests — startSession 200

```json
{
  "id": "exec-1",
  "planId": 4,
  "actualWeekNumber": 1,
  "feeling": "OK",
  "exercises": [
    {
      "id": "ex-1", "name": "Bench Press", "muscle": "Chest",
      "restSeconds": 90,
      "sets": [{"targetReps": 8, "prevWeight": 80.0, "prevReps": 8}],
      "pr": null
    }
  ]
}
```

### ReadyToLiftViewModelTests — beginSession success

```swift
mockService.responseToReturn = makeFixtureResponse()
await sut.beginSession(planId: 4, actualWeekNumber: 1, feeling: "ok", using: mockService)
XCTAssertEqual(sut.loadState, .idle)
XCTAssertNotNil(sut.sessionResponse)
XCTAssertEqual(mockService.lastRequest?.feeling, "OK") // uppercase enforced
```
