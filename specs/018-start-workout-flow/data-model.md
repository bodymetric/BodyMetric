# Data Model: Start Workout Flow

**Branch**: `018-start-workout-flow`  
**Date**: 2026-05-18

---

## Modified Entities

### `WorkoutDayPlanSummary` — add `actualWeekNumber`

Location: `Models/HomeModels.swift`

```swift
struct WorkoutDayPlanSummary: Decodable, Equatable {
    let id: Int
    let name: String
    let dayOfWeek: String
    let numberOfExercisesTotal: Int
    let numberSetsTotal: Int
    let timeEstimateToFinish: Int
    let actualWeekNumber: Int?   // NEW — current training week; nil if not yet tracked by server
}
```

---

## New Entities

### `StartSessionRequest` — POST /api/work-executions/start body

Location: `Models/WorkoutExecutionModels.swift`

```swift
struct StartSessionRequest: Codable {
    let planId: Int
    let actualWeekNumber: Int
    let feeling: String      // always uppercase (e.g., "LOW", "OK", "HIGH")
}
```

---

### `StartSessionResponse` — POST /api/work-executions/start success body

Location: `Models/WorkoutExecutionModels.swift`

```swift
struct StartSessionResponse: Decodable {
    let id: String                        // execution session ID
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
```

---

### Mapping: `StartSessionResponse` → `WorkoutSession`

Location: extension in `Models/WorkoutExecutionModels.swift`

```swift
extension StartSessionResponse {
    func toWorkoutSession() -> WorkoutSession {
        WorkoutSession(
            id: id,
            name: "",                     // not needed by ActiveSessionView header (uses plan name from CheckInView)
            program: "Week \(actualWeekNumber)",
            dayIndex: actualWeekNumber,
            estimatedMinutes: 0,          // not shown in ActiveSessionView header
            exercises: exercises.map { ex in
                WorkoutExercise(
                    id: ex.id,
                    name: ex.name,
                    muscle: ex.muscle,
                    restSeconds: ex.restSeconds,
                    sets: ex.sets.map { s in
                        WorkoutSet(
                            targetReps: s.targetReps,
                            prevWeight: s.prevWeight,
                            prevReps: s.prevReps
                        )
                    },
                    pr: ex.pr.map { PRRecord(weight: $0.weight, reps: $0.reps) }
                )
            }
        )
    }
}
```

---

## New ViewModel

### `ReadyToLiftViewModel`

Location: `Features/Workout/ViewModels/ReadyToLiftViewModel.swift`

```swift
@Observable
@MainActor
final class ReadyToLiftViewModel {

    enum LoadState: Equatable {
        case idle
        case submitting
        case failed(String)
    }

    var loadState: LoadState = .idle
    var sessionResponse: StartSessionResponse? = nil

    var isSubmitting: Bool { loadState == .submitting }

    func beginSession(
        planId: Int,
        actualWeekNumber: Int,
        feeling: String,
        using service: any WorkoutExecutionServiceProtocol
    ) async { ... }
}
```

---

## State Flow

```
CheckInView appears
    → user selects Mood (nil → .low / .ok / .high)
    → "Begin session" button enables

User taps "Begin session"
    → ReadyToLiftViewModel.beginSession()
    → loadState = .submitting (button shows ProgressView)
    
    ← success → loadState = .idle, sessionResponse = response
                 → NavigationLink / NavigationPath pushes ActiveSessionView
                 
    ← failure → loadState = .failed("message")
                 → error banner shown, button re-enabled
```

---

## Service Protocol

### `WorkoutExecutionServiceProtocol`

Location: `Services/WorkoutExecution/WorkoutExecutionServiceProtocol.swift`

```swift
@MainActor
protocol WorkoutExecutionServiceProtocol: AnyObject {
    func startSession(_ request: StartSessionRequest) async throws -> StartSessionResponse
}
```
