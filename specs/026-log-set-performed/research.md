# Research: Log Set Performed

**Feature**: `026-log-set-performed`  
**Date**: 2026-06-11  
**Status**: Complete — all decisions resolved

---

## Decision 1: exerciseBlockExecutionId source

**Decision**: Add `exerciseBlockExecutionId: Int` to `ExerciseBlockPlan` in the start-session response. The server creates one `ExerciseBlockExecution` record per plan block when `POST /api/work-executions/start` is called, and returns its ID in the response.

**Rationale**: The log endpoint `POST /api/exercise-block-executions/{exerciseBlockExecutionId}/performed-sets` requires an execution-level ID, not a plan-level ID. The two are distinct: a plan block can appear in multiple workout sessions; each session creates a fresh execution record with its own ID. Reusing `exerciseBlockPlanId` would be semantically wrong and would route sets to the wrong execution record.

**Alternatives considered**:
- Use `exerciseBlockPlanId` as the execution ID — rejected: plan vs. execution IDs are distinct on the server; using the wrong ID would silently corrupt data.
- Fetch execution IDs in a separate call after session start — rejected: adds an extra round-trip and complexity; the start response can carry the IDs inline.

---

## Decision 2: PerformedSetService as a standalone service

**Decision**: Create `PerformedSetService` + `PerformedSetServiceProtocol` as a new, focused service in `Services/WorkoutExecution/`.

**Rationale**: Single-responsibility principle. `WorkoutExecutionService` handles session start; `PerformedSetService` handles set logging. They share the same `NetworkClient` dependency but remain independently testable and replaceable. This matches the established pattern in the codebase (e.g., `HomeService`, `WorkoutDayPlanService`).

**Alternatives considered**:
- Add `logPerformedSet` to `WorkoutExecutionService` — rejected: conflates two distinct concerns and grows the service's test surface unnecessarily.
- Add a `logSet` method to `ActiveSessionViewModel` calling `NetworkClient` directly — rejected: violates the service-layer abstraction used throughout the app.

---

## Decision 3: Async commitSet pattern

**Decision**: Make `ActiveSessionViewModel.commitSet` async. `ActiveSessionView` wraps the call in `Task { await viewModel.commitSet(...) }`. `isSubmittingLog: Bool` and `logError: String?` are `@Observable` properties on the VM that drive the `LogSetSheet` loading/error state.

**Rationale**: `@Observable` propagates state changes back to the view automatically. Keeping the async call in the VM keeps views dumb. The `Task {}` wrapper in `ActiveSessionView` is the standard SwiftUI pattern for triggering async work from a synchronous button handler.

**Alternatives considered**:
- Make `LogSetSheet.onCommit` `async` — rejected: SwiftUI button `action` closures are synchronous; wrapping async inside them is fragile.
- Debounce via Combine — rejected: overkill for a single-fire button; simple `isSubmittingLog` flag achieves duplicate-prevention with no extra dependencies.

---

## Decision 4: LogSetSheet loading state API

**Decision**: Add `isLoading: Bool` and `error: String?` parameters to `LogSetSheet`. The sheet stays a dumb view driven by the VM via `ActiveSessionView`.

**Rationale**: The sheet already has a clean `onCommit` callback interface. Adding two parameters keeps it testable in isolation and consistent with the "view = pure function of state" philosophy.

**Alternatives considered**:
- Give the sheet direct access to the VM — rejected: couples the sheet to `ActiveSessionViewModel`, making it harder to reuse or preview.
- Dismiss the sheet on submit and show a spinner at the exercise-list level — rejected: poor UX; user loses their entered values if the request fails.

---

## Decision 5: Error message content

**Decision**: Log the error category (server error with status code, or network error) via `Logger.error` with no weight/rep values in the message. The user-facing string is generic ("Failed to log set. Please try again.").

**Rationale**: Constitution Principle III forbids PII in logs. Weight and rep data are personal health data; logging them would violate the principle. The user-visible message is intentionally generic to avoid surface-area for confusion.

**Alternatives considered**:
- Log weight/reps for debugging — rejected: Constitution Principle III explicitly prohibits sensitive health data in logs.
- Show the raw HTTP status code to the user — rejected: violates Constitution Principle V (user-friendly) and exposes implementation details.

---

## Decision 6: Response body handling

**Decision**: The `POST /api/exercise-block-executions/{id}/performed-sets` response body is ignored. Only the HTTP status code matters: 200 or 201 = success; anything else = `WorkoutPlanError.serverError(code)`.

**Rationale**: The spec does not define a response body for this endpoint. Ignoring the body keeps the integration simple and forward-compatible.

**Alternatives considered**:
- Decode a `PerformedSetResponse` struct — rejected: no response shape is specified; decoding an unknown shape risks fragile tests.

---

## Decision 7: Validation gate (reps = 0)

**Decision**: Validate `reps > 0` in `ActiveSessionViewModel.commitSet` before calling the service. Return an `logError` message immediately without a network call.

**Rationale**: FR-007 requires the app to block submission when reps is 0. Client-side validation avoids wasting a network round-trip for a known-invalid input.

**Alternatives considered**:
- Let the server reject 0-rep submissions — rejected: increases latency for a preventable error and requires server error parsing for a UI validation concern.
