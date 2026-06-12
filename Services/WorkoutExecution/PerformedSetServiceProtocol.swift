import Foundation

/// Protocol for logging a performed set on a specific exercise block execution.
///
/// Constitution Principle VII: Bearer token injection is handled by `NetworkClient` — no token
/// handling required in conforming types.
protocol PerformedSetServiceProtocol {
    /// Records `weight` and `reps` for the given exercise block execution.
    ///
    /// Throws `WorkoutPlanError.serverError` on non-200/201 HTTP status,
    /// `WorkoutPlanError.networkError` on transport failure.
    func logPerformedSet(exerciseBlockExecutionId: Int, weight: Double, reps: Int) async throws
}
