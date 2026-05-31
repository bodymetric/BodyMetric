# Research: Start Workout Flow

**Branch**: `018-start-workout-flow`  
**Date**: 2026-05-18

---

## Decision 1: Existing Prototype Views — Update vs. Recreate

**Decision**: Update the existing `CheckInView.swift` and `ActiveSessionView.swift` rather than creating new screens. Both files already exist as complete prototype implementations with the correct visual design and component structure.

**Rationale**: `CheckInView` already implements the "Ready to Lift" mood selector with `Mood` enum (Low/Good/Strong), a warmup checklist, and the "Begin session" CTA. `ActiveSessionView` already implements the full exercise-logging experience with rest timer, set logging, and completion flow. This feature wires them to real API data; the UI itself needs minimal changes.

**What changes in CheckInView**:
- Replace `WorkoutSession` parameter with navigation context from `WorkoutDayPlanSummary`
- Add a ViewModel (`ReadyToLiftViewModel`) to own the API call lifecycle
- Add loading state on the "Begin session" button
- Add error state display

**Alternatives considered**:
- **Create `ReadyToLiftView`**: Avoids touching existing code but duplicates ~260 lines. Rejected — DRY.
- **Leave as stub with callback**: The existing `onBegin(String)` callback pattern is insufficient because the API call and navigation must happen inside the screen, not be delegated up.

---

## Decision 2: Navigation Pattern — fullScreenCover Chain

**Decision**: `TodayView` presents a `NavigationStack` wrapper containing `CheckInView` via `.fullScreenCover`. On session-start success, `CheckInView` pushes `ActiveSessionView` onto its navigation stack.

**Rationale**: Consistent with the wizard pattern (`.fullScreenCover`). `ActiveSessionView` already uses `.navigationBarHidden(true)`, indicating it was designed for full-screen presentation. The `NavigationStack` wrapper inside the cover allows `CheckInView` → `ActiveSessionView` push navigation.

**What this means for TodayView**:
- Add `@State private var showCheckIn = false`
- "Start Workout" button sets `showCheckIn = true`
- `.fullScreenCover(isPresented: $showCheckIn)` presents `CheckInWrapperView` (a lightweight `NavigationStack` shell)

**Alternatives considered**:
- **Push from TodayView's existing NavigationStack**: The existing `path` state in TodayView is unused; this could work but pollutes TodayView's nav path with workout-session concerns.
- **Second fullScreenCover from CheckInView to ActiveSessionView**: Works but two nested fullScreenCovers is harder to dismiss cleanly.

---

## Decision 3: `actualWeekNumber` Source

**Decision**: Add `actualWeekNumber: Int?` to `WorkoutDayPlanSummary` in `HomeModels.swift`. The home screen API (`GET /api/home`) must return this field. If absent (nil), the client defaults to `1` when building the session-start request.

**Rationale**: `WorkoutDayPlanSummary` is already the authoritative plan summary on the home screen. Adding `actualWeekNumber` there makes it available to the "Start Workout" button without an additional network call. `WorkoutPlanDayResponse` already has `actualWeekNumber: Int?` proving the backend tracks this value.

**Alternatives considered**:
- **Fetch from GET /api/workout-plans**: Requires a second network call before starting. Wasteful.
- **Hardcode to 1**: Works for v1 but would break multi-week progression.

---

## Decision 4: Feeling Enum and Uppercase Conversion

**Decision**: Reuse the existing `Mood` enum from `CheckInView` with rawValues `"low"`, `"ok"`, `"high"`. The ViewModel converts to uppercase via `.rawValue.uppercased()` → `"LOW"`, `"OK"`, `"HIGH"` before sending to the backend.

**Rationale**: The spec requires uppercase feeling values. The existing labels ("Low", "Good", "Strong") are user-facing display strings; the rawValues are the API identifiers. `rawValue.uppercased()` is the bridge. No enum changes needed.

**Alternatives considered**:
- **New enum with uppercase rawValues**: Would let us skip `.uppercased()` call but requires changing `CheckInView`'s internal Mood enum. Unnecessary.
- **Map to "GOOD"/"GREAT"/etc.**: The spec's example ("GOOD") is illustrative, not prescriptive. The backend contract (which we're defining) accepts "LOW", "OK", "HIGH".

---

## Decision 5: API Response → WorkoutSession Mapping

**Decision**: Define `StartSessionResponse` as a Decodable DTO containing session ID, plan ID, and an array of `SessionExercise` with nested `SessionSet`. Create an extension `StartSessionResponse.toWorkoutSession(mood:)` that maps to the existing `WorkoutSession` struct used by `ActiveSessionView`.

**Rationale**: `ActiveSessionViewModel` takes a `WorkoutSession` and works correctly with it — no changes needed to the active session experience. A pure mapping function is testable, transparent, and doesn't require modifying `WorkoutSession`.

**Alternatives considered**:
- **Change `ActiveSessionViewModel` to accept API types directly**: Couples the session execution logic to API types. Rejected — separation of concerns.
- **Store raw API response in `ActiveSessionViewModel`**: Makes the VM responsible for mapping. Rejected.

---

## Decision 6: ReadyToLiftViewModel Architecture

**Decision**: Create `ReadyToLiftViewModel` as a `@Observable @MainActor` class (matching existing VM patterns). It holds: `isSubmitting: Bool`, `errorMessage: String?`, `sessionResponse: StartSessionResponse?`, and the `beginSession(using:planId:actualWeekNumber:feeling:)` async action.

**Rationale**: Follows the established pattern of `TodayViewModel` and `NewPlanViewModel`. The ViewModel owns the API call lifecycle and error state; `CheckInView` observes it reactively.

---

## Decision 7: Service Layer Structure

**Decision**: Create `Services/WorkoutExecution/WorkoutExecutionService.swift` + `WorkoutExecutionServiceProtocol.swift` following the exact same structure as `WorkoutPlanService`. Single method: `startSession(_ request: StartSessionRequest) async throws -> StartSessionResponse`.

**Rationale**: Consistent with established service layer patterns. Separate service directory keeps workout execution concerns isolated from plan management.

---

## Decision 8: WorkoutExecutionService Error Handling

**Decision**: Reuse `WorkoutPlanError` enum (already has `.serverError`, `.networkError`, `.decodingError`) rather than creating a new error type. The execution service throws the same error variants.

**Rationale**: The existing error enum covers all cases needed. Adding a new error enum for one service is unnecessary fragmentation. Constitution Principle III requires all errors to be logged — reusing the existing pattern satisfies this.
